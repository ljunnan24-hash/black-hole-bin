import { invoke, isTauri } from "@tauri-apps/api/core";
import { getCurrentWebview } from "@tauri-apps/api/webview";

const runningInTauri = isTauri();
const prefersChinese = navigator.languages?.some((language) =>
  language.toLowerCase().startsWith("zh")
);

const copy = prefersChinese
  ? {
      app: "黑洞垃圾箱",
      drop: "拖入文件，松手移入回收站",
      release: "松手移入回收站",
      absorbing: (count) => `正在吸入 ${count} 个项目…`,
      recycled: (count) => `已移入回收站 · ${count} 个项目`,
      failed: "操作失败；部分项目可能已经进入回收站",
      preview: "动画预览，不会移动任何文件",
      menu: "打开菜单",
      move: "移动黑洞垃圾箱",
      openBin: "打开回收站",
      alwaysOnTop: "始终置顶",
      reduceMotion: "减少动态效果",
      quit: "退出",
      noWebgl: "无法启动 WebGL 黑洞渲染",
    }
  : {
      app: "Black Hole Bin",
      drop: "Drop files, then release to recycle",
      release: "Release to recycle",
      absorbing: (count) => `Absorbing ${count} item${count === 1 ? "" : "s"}…`,
      recycled: (count) =>
        `Moved to Recycle Bin · ${count} item${count === 1 ? "" : "s"}`,
      failed: "Could not finish; some items may already be in the Recycle Bin",
      preview: "Animation preview — no files were moved",
      menu: "Open menu",
      move: "Move Black Hole Bin",
      openBin: "Open Recycle Bin",
      alwaysOnTop: "Always on top",
      reduceMotion: "Reduce motion",
      quit: "Quit",
      noWebgl: "The WebGL black-hole renderer could not start",
    };

const elements = {
  app: document.querySelector("#app"),
  renderer: document.querySelector("#renderer"),
  dropZone: document.querySelector("#drop-zone"),
  dropHint: document.querySelector("#drop-hint"),
  status: document.querySelector("#status"),
  particles: document.querySelector("#particles"),
  dragHandle: document.querySelector("#drag-handle"),
  menuButton: document.querySelector("#menu-button"),
  menu: document.querySelector("#context-menu"),
  accessibleName: document.querySelector("#drop-accessible-name"),
  menuOpenBin: document.querySelector('[data-action="recycle-bin"]'),
  menuAlwaysOnTop: document.querySelector('[data-action="always-on-top"]'),
  menuReduceMotion: document.querySelector('[data-action="reduce-motion"]'),
  menuQuit: document.querySelector('[data-action="quit"]'),
};

let rendererReady = false;
let processingDrop = false;
let fileDragActive = false;
let statusTimer;
let menuOpen = false;

const storedReducedMotion = localStorage.getItem("black-hole-reduced-motion");
let reducedMotion =
  storedReducedMotion === null
    ? window.matchMedia("(prefers-reduced-motion: reduce)").matches
    : storedReducedMotion === "true";
let alwaysOnTop = localStorage.getItem("black-hole-always-on-top") !== "false";

document.documentElement.lang = prefersChinese ? "zh-CN" : "en";
document.title = copy.app;
elements.app.setAttribute("aria-label", copy.app);
elements.dropZone.setAttribute("aria-label", copy.drop);
elements.accessibleName.textContent = copy.drop;
elements.dropHint.textContent = copy.release;
elements.dragHandle.setAttribute("aria-label", copy.move);
elements.menuButton.setAttribute("aria-label", copy.menu);
elements.menuOpenBin.textContent = copy.openBin;
elements.menuAlwaysOnTop.querySelector("span").textContent = copy.alwaysOnTop;
elements.menuReduceMotion.querySelector("span").textContent = copy.reduceMotion;
elements.menuQuit.textContent = copy.quit;

function rendererCall(method, ...arguments_) {
  if (!rendererReady) return;
  const target = elements.renderer.contentWindow;
  if (typeof target?.[method] === "function") {
    target[method](...arguments_);
  }
}

function clamp(value, minimum = -1, maximum = 1) {
  return Math.min(Math.max(value, minimum), maximum);
}

function dragVectorFromPhysicalPosition(position) {
  const scale = window.devicePixelRatio || 1;
  const x = position.x / scale;
  const y = position.y / scale;
  return [
    clamp((x / window.innerWidth - 0.5) * 2),
    clamp(((window.innerHeight - y) / window.innerHeight - 0.5) * 2),
  ];
}

function dragVectorFromPointer(event) {
  return [
    clamp((event.clientX / window.innerWidth - 0.5) * 2),
    clamp(((window.innerHeight - event.clientY) / window.innerHeight - 0.5) * 2),
  ];
}

function setInteraction(hover, vector = [0, 0]) {
  rendererCall("blackHoleSetInteraction", hover, vector[0], vector[1]);
}

function setAttraction(active) {
  elements.app.classList.toggle("attracting", active);
  elements.dropHint.setAttribute("aria-hidden", String(!active));
}

function setStatus(message, kind = "neutral", duration = 2600) {
  window.clearTimeout(statusTimer);
  elements.status.textContent = message;
  elements.status.dataset.kind = kind;
  elements.status.classList.toggle("visible", Boolean(message));
  if (message && duration > 0) {
    statusTimer = window.setTimeout(() => {
      elements.status.classList.remove("visible");
    }, duration);
  }
}

function sleep(milliseconds) {
  return new Promise((resolve) => window.setTimeout(resolve, milliseconds));
}

function fileName(path) {
  const segments = path.split(/[\\/]/).filter(Boolean);
  return segments.at(-1) || copy.app;
}

function createSuctionParticles(paths) {
  const visiblePaths = paths.slice(0, 7);
  const radius = Math.min(window.innerWidth, window.innerHeight) * 0.38;

  visiblePaths.forEach((path, index) => {
    const angle = (Math.PI * 2 * index) / visiblePaths.length - Math.PI / 2;
    const particle = document.createElement("div");
    const label = document.createElement("span");
    particle.className = "file-particle";
    particle.style.setProperty("--from-x", `${Math.cos(angle) * radius}px`);
    particle.style.setProperty("--from-y", `${Math.sin(angle) * radius}px`);
    particle.style.setProperty("--turn", `${540 + index * 52}deg`);
    particle.style.setProperty("--delay", `${index * 45}ms`);
    label.textContent = fileName(path);
    particle.append(label);
    elements.particles.append(particle);
    particle.addEventListener("animationend", () => particle.remove(), { once: true });
  });
}

async function recyclePaths(paths) {
  const uniquePaths = [...new Set(paths)].filter(Boolean);
  if (processingDrop || uniquePaths.length === 0) return;

  processingDrop = true;
  fileDragActive = false;
  closeMenu();
  setAttraction(false);
  elements.app.classList.add("sucking");
  setInteraction(1);
  rendererCall("blackHolePulse", "suction");
  createSuctionParticles(uniquePaths);
  setStatus(copy.absorbing(uniquePaths.length), "neutral", 0);

  await sleep(reducedMotion ? 100 : 720);

  try {
    const result = await invoke("move_to_recycle_bin", { paths: uniquePaths });
    rendererCall("blackHolePulse", "success");
    setStatus(copy.recycled(result.count), "success");
  } catch (error) {
    console.error("Recycle failed:", error);
    rendererCall("blackHolePulse", "error");
    setStatus(copy.failed, "error", 4200);
  } finally {
    processingDrop = false;
    elements.app.classList.remove("sucking");
    setInteraction(0);
  }
}

function previewSuction() {
  if (processingDrop || fileDragActive) return;
  processingDrop = true;
  setInteraction(1);
  setAttraction(false);
  elements.app.classList.add("sucking");
  rendererCall("blackHolePulse", "suction");
  createSuctionParticles(["Preview.txt"]);
  setStatus(copy.preview);

  window.setTimeout(
    () => {
      processingDrop = false;
      elements.app.classList.remove("sucking");
      setInteraction(0);
    },
    reducedMotion ? 180 : 980
  );
}

function applyReducedMotion(value) {
  reducedMotion = value;
  localStorage.setItem("black-hole-reduced-motion", String(value));
  elements.app.classList.toggle("reduced-motion", value);
  elements.menuReduceMotion.setAttribute("aria-checked", String(value));
  rendererCall("blackHoleSetReducedMotion", value);
}

async function applyAlwaysOnTop(value) {
  if (!runningInTauri) {
    alwaysOnTop = value;
    elements.menuAlwaysOnTop.setAttribute("aria-checked", String(value));
    return;
  }

  try {
    await invoke("set_always_on_top", { enabled: value });
    alwaysOnTop = value;
    localStorage.setItem("black-hole-always-on-top", String(value));
    elements.menuAlwaysOnTop.setAttribute("aria-checked", String(value));
  } catch (error) {
    console.error("Could not change always-on-top state:", error);
  }
}

function openMenu() {
  menuOpen = true;
  elements.menu.hidden = false;
  elements.menuButton.setAttribute("aria-expanded", "true");
  elements.menuOpenBin.focus();
}

function closeMenu() {
  if (!menuOpen) return;
  menuOpen = false;
  elements.menu.hidden = true;
  elements.menuButton.setAttribute("aria-expanded", "false");
}

function toggleMenu() {
  if (menuOpen) closeMenu();
  else openMenu();
}

elements.renderer.addEventListener("load", () => {
  rendererReady = true;
  applyReducedMotion(reducedMotion);
  setInteraction(0);
});

elements.renderer.addEventListener("error", () => {
  setStatus(copy.noWebgl, "error", 0);
});

elements.dropZone.addEventListener("pointerenter", (event) => {
  if (processingDrop || fileDragActive) return;
  setAttraction(true);
  setInteraction(0.48, dragVectorFromPointer(event));
});

elements.dropZone.addEventListener("pointermove", (event) => {
  if (processingDrop || fileDragActive) return;
  setInteraction(0.48, dragVectorFromPointer(event));
});

elements.dropZone.addEventListener("pointerleave", () => {
  if (processingDrop || fileDragActive) return;
  setAttraction(false);
  setInteraction(0);
});

elements.dropZone.addEventListener("dblclick", previewSuction);
elements.dropZone.addEventListener("keydown", (event) => {
  if (event.key === "Enter" || event.key === " ") {
    event.preventDefault();
    previewSuction();
  }
});

elements.dragHandle.addEventListener("pointerdown", async (event) => {
  if (event.button !== 0 || !runningInTauri) return;
  closeMenu();
  try {
    await invoke("start_dragging");
  } catch (error) {
    console.error("Could not move window:", error);
  }
});

elements.menuButton.addEventListener("click", (event) => {
  event.stopPropagation();
  toggleMenu();
});

window.addEventListener("contextmenu", (event) => {
  event.preventDefault();
  openMenu();
});

window.addEventListener("pointerdown", (event) => {
  if (menuOpen && !elements.menu.contains(event.target) && event.target !== elements.menuButton) {
    closeMenu();
  }
});

window.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeMenu();
});

elements.menu.addEventListener("click", async (event) => {
  const action = event.target.closest("[data-action]")?.dataset.action;
  if (!action) return;

  if (action === "recycle-bin") {
    closeMenu();
    if (runningInTauri) {
      await invoke("open_recycle_bin").catch((error) => console.error(error));
    }
  } else if (action === "always-on-top") {
    await applyAlwaysOnTop(!alwaysOnTop);
  } else if (action === "reduce-motion") {
    applyReducedMotion(!reducedMotion);
  } else if (action === "quit") {
    if (runningInTauri) await invoke("close_app");
  }
});

async function registerFileDrop() {
  await getCurrentWebview().onDragDropEvent((event) => {
    const payload = event.payload;

    if (payload.type === "over" && !processingDrop) {
      fileDragActive = true;
      setAttraction(true);
      setInteraction(1, dragVectorFromPhysicalPosition(payload.position));
    } else if (payload.type === "leave" && !processingDrop) {
      fileDragActive = false;
      setAttraction(false);
      setInteraction(0);
    } else if (payload.type === "drop") {
      fileDragActive = false;
      recyclePaths(payload.paths);
    }
  });
}

applyReducedMotion(reducedMotion);
applyAlwaysOnTop(alwaysOnTop);
if (runningInTauri) {
  registerFileDrop().catch((error) => {
    console.error("Could not register file-drop listener:", error);
    setStatus(String(error), "error", 0);
  });
} else {
  elements.dragHandle.hidden = true;
}
