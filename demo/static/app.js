const symbols = ["AAPL", "MSFT", "NFLX"];
let selectedSymbol = "MSFT";
let latestState = null;

const statusEl = document.getElementById("status");
const connectionEl = document.getElementById("connection");
const runButton = document.getElementById("run-button");
const detailEl = document.getElementById("detail");
const errorEl = document.getElementById("error");
const mismatchEl = document.getElementById("mismatch-detail");
const progressBar = document.getElementById("progress-bar");
const graph = document.getElementById("bbo-graph");
const graphWindowEl = document.getElementById("graph-window");

function formatInteger(value) {
  return value == null ? "—" : Number(value).toLocaleString("en-GB");
}

function formatPrice(cents) {
  return cents == null ? "—" : `$${(Number(cents) / 100).toFixed(2)}`;
}

function makeStockCards() {
  const root = document.getElementById("stock-cards");
  root.innerHTML = symbols.map(symbol => `
    <article class="stock-card" id="card-${symbol}">
      <div class="stock-title">
        <h2>${symbol}</h2>
        <span id="${symbol}-locate">locate —</span>
      </div>
      <div class="quote-row">
        <div>
          <span>Best Bid</span>
          <strong id="${symbol}-bid">—</strong>
          <small id="${symbol}-bid-size">— shares</small>
        </div>
        <div>
          <span>Best Ask</span>
          <strong id="${symbol}-ask">—</strong>
          <small id="${symbol}-ask-size">— shares</small>
        </div>
      </div>
      <div class="spread">
        <span>Spread</span>
        <strong id="${symbol}-spread">—</strong>
      </div>
      <div class="oracle-stock">
        <span>Oracle</span>
        <strong id="${symbol}-oracle">0 / —</strong>
      </div>
    </article>
  `).join("");
}

function setStatus(status) {
  const value = status || "IDLE";
  statusEl.textContent = value;
  statusEl.className = `status ${value.toLowerCase()}`;
  runButton.disabled = value === "INITIALISING" || value === "RUNNING";
}

function setConnection(ok) {
  connectionEl.textContent = ok ? "ONLINE" : "OFFLINE";
  connectionEl.className = `connection ${ok ? "online" : "offline"}`;
}

function updateCards(state) {
  const verification = state.verification || {};
  const expectedByStock = verification.expected_by_stock || {};
  const observedByStock = verification.observed_by_stock || {};

  for (const symbol of symbols) {
    const stock = state.stocks[symbol];
    const mapping = state.mappings[symbol];

    document.getElementById(`${symbol}-bid`).textContent =
      formatPrice(stock.bid_price);
    document.getElementById(`${symbol}-ask`).textContent =
      formatPrice(stock.ask_price);

    document.getElementById(`${symbol}-bid-size`).textContent =
      stock.bid_size == null ? "— shares" : `${formatInteger(stock.bid_size)} shares`;
    document.getElementById(`${symbol}-ask-size`).textContent =
      stock.ask_size == null ? "— shares" : `${formatInteger(stock.ask_size)} shares`;

    document.getElementById(`${symbol}-spread`).textContent =
      stock.spread == null ? "—" : `${formatInteger(stock.spread)}¢`;

    document.getElementById(`${symbol}-locate`).textContent =
      mapping ? `locate 0x${Number(mapping.locate).toString(16).padStart(4, "0")}` : "locate —";

    const observed = Number(observedByStock[symbol] || 0);
    const expected = expectedByStock[symbol];
    document.getElementById(`${symbol}-oracle`).textContent =
      `${formatInteger(observed)} / ${expected == null ? "—" : formatInteger(expected)}`;
  }
}

function svgEl(name, attrs = {}, text = null) {
  const el = document.createElementNS("http://www.w3.org/2000/svg", name);
  for (const [key, value] of Object.entries(attrs)) {
    el.setAttribute(key, value);
  }
  if (text != null) el.textContent = text;
  return el;
}

function stepPath(history, key, x, y) {
  let path = "";
  let previous = null;

  for (const point of history) {
    const value = point[key];
    if (value == null) {
      previous = null;
      continue;
    }

    const xx = x(point.index);
    const yy = y(value);

    if (previous == null) {
      path += `M ${xx.toFixed(2)} ${yy.toFixed(2)} `;
    } else {
      path += `H ${xx.toFixed(2)} V ${yy.toFixed(2)} `;
    }
    previous = point;
  }

  return path.trim();
}

function drawGraph(stock) {
  graph.replaceChildren();

  const history = stock?.history || [];
  const historyTotal = Number(stock?.history_total || history.length || 0);
  const historyLimit = Number(stock?.history_limit || 0);

  const width = 960;
  const height = 340;
  const left = 72;
  const right = 24;
  const top = 24;
  const bottom = 48;
  const plotWidth = width - left - right;
  const plotHeight = height - top - bottom;

  const values = [];
  for (const point of history) {
    if (point.bid != null) values.push(Number(point.bid));
    if (point.ask != null) values.push(Number(point.ask));
  }

  if (!history.length || !values.length) {
    graphWindowEl.textContent = "";
    graph.appendChild(svgEl("text", {
      x: width / 2,
      y: height / 2,
      "text-anchor": "middle",
      class: "empty-graph"
    }, "Waiting for BBO updates…"));
    return;
  }

  const firstIndex = Number(history[0].index);
  const lastIndex = Number(history[history.length - 1].index);
  const shown = history.length;
  graphWindowEl.textContent = historyTotal > shown
    ? `Latest ${formatInteger(shown)} of ${formatInteger(historyTotal)} BBO updates`
    : `${formatInteger(shown)} BBO updates`;

  if (historyLimit > 0 && historyTotal >= historyLimit) {
    graphWindowEl.title =
      "The graph keeps only the latest display window; oracle comparison still covers the full replay.";
  } else {
    graphWindowEl.removeAttribute("title");
  }

  let minY = Math.min(...values);
  let maxY = Math.max(...values);
  if (minY === maxY) {
    minY -= 1;
    maxY += 1;
  }

  const pad = Math.max(1, Math.ceil((maxY - minY) * 0.08));
  minY -= pad;
  maxY += pad;

  const xSpan = Math.max(1, lastIndex - firstIndex);
  const x = index => left + ((Number(index) - firstIndex) / xSpan) * plotWidth;
  const y = price => top + ((maxY - Number(price)) / (maxY - minY)) * plotHeight;

  for (let i = 0; i <= 4; i += 1) {
    const yy = top + (i / 4) * plotHeight;
    const price = maxY - (i / 4) * (maxY - minY);
    graph.appendChild(svgEl("line", {
      x1: left,
      x2: width - right,
      y1: yy,
      y2: yy,
      class: "grid-line"
    }));
    graph.appendChild(svgEl("text", {
      x: left - 12,
      y: yy + 4,
      "text-anchor": "end",
      class: "tick-label"
    }, formatPrice(price)));
  }

  if (lastIndex === firstIndex) {
    graph.appendChild(svgEl("text", {
      x: left,
      y: height - 17,
      class: "tick-label"
    }, String(firstIndex)));
  } else {
    for (let i = 0; i <= 4; i += 1) {
      const index = Math.round(firstIndex + (i / 4) * (lastIndex - firstIndex));
      const xx = x(index);
      if (i > 0 && i < 4) {
        graph.appendChild(svgEl("line", {
          x1: xx,
          x2: xx,
          y1: top,
          y2: height - bottom,
          class: "grid-line"
        }));
      }
      graph.appendChild(svgEl("text", {
        x: xx,
        y: height - 17,
        "text-anchor": i === 0 ? "start" : (i === 4 ? "end" : "middle"),
        class: "tick-label"
      }, String(index)));
    }
  }

  graph.appendChild(svgEl("line", {
    x1: left,
    x2: left,
    y1: top,
    y2: height - bottom,
    class: "axis-line"
  }));
  graph.appendChild(svgEl("line", {
    x1: left,
    x2: width - right,
    y1: height - bottom,
    y2: height - bottom,
    class: "axis-line"
  }));

  const bidPath = stepPath(history, "bid", x, y);
  const askPath = stepPath(history, "ask", x, y);

  if (bidPath) {
    graph.appendChild(svgEl("path", {
      d: bidPath,
      class: "bid-line"
    }));
  }
  if (askPath) {
    graph.appendChild(svgEl("path", {
      d: askPath,
      class: "ask-line"
    }));
  }
}

function renderMismatch(verification) {
  const first = verification.first_mismatch;
  if (!first) {
    mismatchEl.textContent = "";
    mismatchEl.classList.add("hidden");
    return;
  }

  mismatchEl.textContent =
    `First mismatch: ${JSON.stringify(first)}`;
  mismatchEl.classList.remove("hidden");
}

function render(state) {
  latestState = state;
  setConnection(true);
  setStatus(state.status);
  detailEl.textContent = state.detail || "";

  const progress = state.progress;
  const verification = state.verification || {};

  document.getElementById("source-messages").textContent =
    formatInteger(progress.source_messages);
  document.getElementById("dma-packets").textContent =
    formatInteger(progress.dma_packets);
  document.getElementById("bbo-updates").textContent =
    formatInteger(progress.bbo_updates);
  document.getElementById("oracle-comparisons").textContent =
    formatInteger(verification.comparisons || 0);
  document.getElementById("mismatches").textContent =
    formatInteger(verification.mismatches || 0);

  const limit = Number(progress.message_limit || 0);
  const source = Number(progress.source_messages || 0);
  const pct = limit > 0 ? Math.min(100, (source / limit) * 100) : 0;
  progressBar.style.width = `${pct}%`;

  const expectedTotal = Number(verification.expected_total || 0);
  const comparisons = Number(verification.comparisons || 0);
  document.getElementById("oracle-progress").textContent =
    expectedTotal > 0
      ? `Oracle ${formatInteger(comparisons)} / ${formatInteger(expectedTotal)}`
      : "";

  if (state.error) {
    errorEl.textContent = state.error;
    errorEl.classList.remove("hidden");
  } else {
    errorEl.textContent = "";
    errorEl.classList.add("hidden");
  }

  renderMismatch(verification);
  updateCards(state);
  drawGraph(state.stocks[selectedSymbol]);
}

async function pollState() {
  try {
    const response = await fetch("/api/state", { cache: "no-store" });
    if (!response.ok) throw new Error(`state request failed: ${response.status}`);
    render(await response.json());
  } catch (error) {
    setConnection(false);
  }
}

runButton.addEventListener("click", async () => {
  runButton.disabled = true;
  errorEl.classList.add("hidden");

  try {
    const response = await fetch("/api/run", { method: "POST" });
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error || "Run request failed");
    await pollState();
  } catch (error) {
    errorEl.textContent = String(error);
    errorEl.classList.remove("hidden");
    runButton.disabled = false;
  }
});

document.getElementById("stock-selector").addEventListener("click", event => {
  const button = event.target.closest("button[data-symbol]");
  if (!button) return;

  selectedSymbol = button.dataset.symbol;
  document.querySelectorAll("#stock-selector button").forEach(el => {
    el.classList.toggle("selected", el === button);
  });

  if (latestState) {
    drawGraph(latestState.stocks[selectedSymbol]);
  }
});

makeStockCards();
pollState();
setInterval(pollState, 500);
