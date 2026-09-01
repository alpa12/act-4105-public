const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

export function enumerateRevealSlides(horizontalSlides, { includeFragments = true } = {}) {
  const result = [];
  horizontalSlides.forEach((horizontal, h) => {
    const verticalSlides = horizontal.verticalSlides?.length ? horizontal.verticalSlides : [horizontal];
    verticalSlides.forEach((vertical, v) => {
      const fragmentCount = Number(vertical.fragmentCount ?? horizontal.fragmentCount ?? 0);
      const states = includeFragments && fragmentCount > 0 ? [null, ...Array.from({ length: fragmentCount }, (_, f) => f)] : [null];
      states.forEach((f) => result.push({ h, v, f }));
    });
  });
  return result;
}

export function revealStructureExpression() {
  return `(() => {
    const horizontal = Reveal.getSlides();
    return horizontal.map((slide) => {
      const verticalSlides = [...slide.children].filter((item) => item.tagName === 'SECTION');
      const slides = verticalSlides.length ? verticalSlides : [slide];
      return { verticalSlides: slides.map((item) => ({ fragmentCount: item.querySelectorAll('.fragment').length })) };
    });
  })()`;
}

export function slideStateExpression() {
  return `(() => {
    const slide = Reveal.getCurrentSlide?.() || document.querySelector('section.present');
    const title = slide?.querySelector('h1,h2,h3')?.textContent?.trim() || '';
    const rect = slide?.getBoundingClientRect();
    const viewport = { width: window.innerWidth, height: window.innerHeight };
    const visible = (element) => {
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0' &&
        !element.closest('[aria-hidden="true"], aside.notes, .controls, .progress, .slide-number, .speaker-notes') &&
        (!element.classList.contains('fragment') || element.classList.contains('visible')) && rect.width > 0 && rect.height > 0;
    };
    const selectors = 'h1,h2,h3,h4,h5,h6,p,li,dt,dd,pre,blockquote,table,figure,img,canvas,video,iframe,mjx-container,.columns,.column,.callout,.cell-output';
    const candidates = slide ? [...slide.querySelectorAll(selectors)] : [];
    const elements = [...new Set(candidates)].filter((element) =>
      element.matches('table,pre,svg,mjx-container') || !element.closest('table,pre,svg,mjx-container')
    ).filter(visible);
    const overflow = elements.map((element) => {
      const box = element.getBoundingClientRect();
      return { tag: element.tagName.toLowerCase(), text: (element.textContent || '').trim().slice(0, 120),
        left: box.left, right: box.right, top: box.top, bottom: box.bottom };
    }).filter((box) => box.left < -6 || box.right > viewport.width + 6 || box.top < -6 || box.bottom > viewport.height + 6);
    const images = elements.filter((element) => element.tagName === 'IMG').map((image) => ({
      src: image.currentSrc || image.src, complete: image.complete, naturalWidth: image.naturalWidth, naturalHeight: image.naturalHeight,
    }));
    return { title, rect: rect && { left: rect.left, top: rect.top, width: rect.width, height: rect.height }, overflow, images,
      overviewCount: document.querySelectorAll('section.progress-overview').length,
      ready: Boolean(window.Reveal?.isReady?.()) };
  })()`;
}

export async function navigate(cdp, url) {
  await cdp.send("Page.enable");
  await cdp.send("Runtime.enable");
  await cdp.send("Network.enable");
  await cdp.send("Log.enable");
  await cdp.send("Page.navigate", { url });
}

export async function waitForReveal(cdp, { timeoutMs = 15000, requirePrintPages = false } = {}) {
  const deadline = Date.now() + timeoutMs;
  let lastPages = -1;
  let stable = 0;
  while (Date.now() < deadline) {
    const result = await cdp.send("Runtime.evaluate", {
      awaitPromise: true,
      returnByValue: true,
      expression: `(async () => {
        const images = [...document.images];
        const mathjaxReady = !window.MathJax || !window.MathJax.startup?.promise ||
          await window.MathJax.startup.promise.then(() => true).catch(() => false);
        const overview = document.querySelector('section.progress-overview');
        const overviewReady = !overview || overview.querySelectorAll('.act-print-overview-list li').length > 0 || !document.documentElement.classList.contains('print-pdf');
        if (document.fonts?.ready) await document.fonts.ready;
        return { reveal: Boolean(window.Reveal?.isReady?.()), fonts: !document.fonts || document.fonts.status === 'loaded',
          mathjaxReady, images: images.every((image) => image.complete), pages: document.querySelectorAll('.pdf-page').length,
          overviewReady };
      })()`
    });
    const state = result.result?.value || {};
    const pagesStable = state.pages === lastPages;
    stable = pagesStable ? stable + 1 : 0;
    lastPages = state.pages;
    if (state.reveal && state.fonts && state.mathjaxReady && state.images && state.overviewReady &&
        (!requirePrintPages || state.pages > 0) && stable >= 3) return state;
    await sleep(200);
  }
  throw new Error(`RevealJS did not become ready within ${timeoutMs} ms`);
}

export async function evaluate(cdp, expression, options = {}) {
  const result = await cdp.send("Runtime.evaluate", { returnByValue: true, awaitPromise: true, expression, ...options });
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || "Runtime evaluation failed");
  return result.result?.value;
}
