const TOKEN_KEY = "claimpal_admin_token";

const state = {
  token: sessionStorage.getItem(TOKEN_KEY) || "",
  currentItem: null,
  busy: false,
};

const elements = {
  pendingBadge: document.getElementById("pendingBadge"),
  rawMeta: document.getElementById("rawMeta"),
  sourceLink: document.getElementById("sourceLink"),
  sourceUrl: document.getElementById("sourceUrl"),
  rawContent: document.getElementById("rawContent"),
  reviewForm: document.getElementById("reviewForm"),
  brandName: document.getElementById("brandName"),
  maxPayout: document.getElementById("maxPayout"),
  country: document.getElementById("country"),
  proofRequired: document.getElementById("proofRequired"),
  deadline: document.getElementById("deadline"),
  eligibilityText: document.getElementById("eligibilityText"),
  message: document.getElementById("message"),
  approveButton: document.getElementById("approveButton"),
  rejectButton: document.getElementById("rejectButton"),
};

const formControls = [
  elements.brandName,
  elements.maxPayout,
  elements.country,
  elements.proofRequired,
  elements.deadline,
  elements.eligibilityText,
];

const actionButtons = [elements.approveButton, elements.rejectButton];

const fieldElements = {
  brand_name: elements.brandName,
  max_payout: elements.maxPayout,
  country: elements.country,
  deadline: elements.deadline,
  eligibility_text: elements.eligibilityText,
};

const fieldErrors = {
  brand_name: document.getElementById("brand_nameError"),
  max_payout: document.getElementById("max_payoutError"),
  country: document.getElementById("countryError"),
  deadline: document.getElementById("deadlineError"),
  eligibility_text: document.getElementById("eligibility_textError"),
};

function createApiError(status, detail, payload = null) {
  const error = new Error(detail || "Request failed.");
  error.status = status;
  error.payload = payload;
  return error;
}

function setToken(token) {
  state.token = token.trim();

  if (state.token) {
    sessionStorage.setItem(TOKEN_KEY, state.token);
  } else {
    sessionStorage.removeItem(TOKEN_KEY);
  }
}

function promptForToken() {
  const enteredToken = window.prompt("Enter ClaimPal admin bearer token", "");

  if (!enteredToken || !enteredToken.trim()) {
    throw createApiError(401, "Admin token is required to load the review queue.");
  }

  setToken(enteredToken);
}

function ensureToken() {
  if (!state.token) {
    promptForToken();
  }
}

async function apiFetch(path, options = {}) {
  ensureToken();

  const response = await fetch(path, {
    ...options,
    headers: {
      Authorization: `Bearer ${state.token}`,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });

  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("application/json") ? await response.json() : null;

  if (response.status === 401 || response.status === 403) {
    setToken("");
    throw createApiError(
      response.status,
      "Authorization failed. Re-enter the admin token on the next action.",
      payload,
    );
  }

  if (!response.ok) {
    throw createApiError(response.status, payload?.detail || "Request failed.", payload);
  }

  return payload;
}

function showMessage(text, kind = "success") {
  elements.message.textContent = text;
  elements.message.className =
    kind === "error"
      ? "rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
      : kind === "warning"
        ? "rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800"
        : "rounded border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800";
}

function clearMessage() {
  elements.message.textContent = "";
  elements.message.className = "hidden rounded border px-3 py-2 text-sm";
}

function clearFieldErrors() {
  Object.entries(fieldErrors).forEach(([name, errorElement]) => {
    if (!errorElement) {
      return;
    }

    errorElement.textContent = "";
    errorElement.classList.add("hidden");
    fieldElements[name]?.classList.remove("border-red-500", "ring-2", "ring-red-100");
  });
}

function showFieldError(fieldName, message) {
  const errorElement = fieldErrors[fieldName];
  const fieldElement = fieldElements[fieldName];

  if (!errorElement || !fieldElement) {
    return;
  }

  errorElement.textContent = message;
  errorElement.classList.remove("hidden");
  fieldElement.classList.add("border-red-500", "ring-2", "ring-red-100");
}

function applyValidationErrors(detail) {
  if (!Array.isArray(detail)) {
    return false;
  }

  clearFieldErrors();
  let handled = false;

  detail.forEach((entry) => {
    const fieldName = entry?.loc?.[entry.loc.length - 1];

    if (typeof fieldName === "string" && fieldErrors[fieldName]) {
      showFieldError(fieldName, entry.msg || "Invalid value.");
      handled = true;
    }
  });

  return handled;
}

function setControlsDisabled(disabled) {
  formControls.forEach((control) => {
    control.disabled = disabled;
  });
}

function setBusy(isBusy) {
  state.busy = isBusy;

  const hasItem = Boolean(state.currentItem);
  setControlsDisabled(isBusy || !hasItem);
  actionButtons.forEach((button) => {
    button.disabled = isBusy || !hasItem;
  });
}

function setEmptyState(rawMessage = "No pending settlements.") {
  state.currentItem = null;
  elements.pendingBadge.textContent = "Pending Review List: 0 items left";
  elements.rawMeta.textContent = "Review queue is empty.";
  elements.rawContent.textContent = rawMessage;
  elements.reviewForm.reset();
  elements.sourceLink.classList.add("hidden");
  elements.sourceUrl.classList.add("hidden");
  elements.sourceLink.removeAttribute("href");
  elements.sourceUrl.textContent = "";
  clearFieldErrors();
  setBusy(false);
}

function renderSourceUrl(sourceUrl) {
  if (!sourceUrl) {
    elements.sourceLink.classList.add("hidden");
    elements.sourceLink.removeAttribute("href");
    elements.sourceUrl.textContent = "Source URL: Not provided. Review using the raw captured content.";
    elements.sourceUrl.className =
      "mt-3 truncate rounded border border-amber-200 bg-amber-50 px-3 py-2 text-xs font-medium text-amber-800";
    return;
  }

  elements.sourceLink.href = sourceUrl;
  elements.sourceLink.classList.remove("hidden");
  elements.sourceUrl.textContent = `Source URL: ${sourceUrl}`;
  elements.sourceUrl.className =
    "mt-3 truncate rounded border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-600";
}

function renderQueue(payload, successMessage = "") {
  const item = payload?.item || null;
  const count = payload?.count ?? 0;

  clearFieldErrors();
  elements.pendingBadge.textContent = `Pending Review List: ${count} items left`;
  state.currentItem = item;

  if (!item) {
    setEmptyState("No pending settlements.");
    showMessage(successMessage || "Review queue is empty.", "success");
    return;
  }

  elements.rawMeta.textContent = `Content type: ${item.raw_content_type || "text"}`;
  elements.rawContent.textContent = item.raw_content || "";
  elements.brandName.value = item.brand_name || "";
  elements.maxPayout.value = item.max_payout ?? "";
  elements.country.value = item.country === "CA" ? "CA" : "US";
  elements.proofRequired.checked = Boolean(item.proof_required);
  elements.deadline.value = item.deadline ? String(item.deadline).slice(0, 10) : "";
  elements.eligibilityText.value = item.eligibility_text || "";

  renderSourceUrl(item.source_url);
  setBusy(false);

  if (successMessage) {
    showMessage(successMessage, "success");
  } else {
    clearMessage();
  }
}

function collectFormPayload() {
  return {
    brand_name: elements.brandName.value.trim(),
    max_payout: elements.maxPayout.value || null,
    country: elements.country.value,
    proof_required: elements.proofRequired.checked,
    deadline: elements.deadline.value || null,
    eligibility_text: elements.eligibilityText.value.trim() || null,
  };
}

function handleRequestError(error, fallbackMessage) {
  const hasFieldErrors = applyValidationErrors(error.payload?.detail);
  showMessage(hasFieldErrors ? "Fix the highlighted fields before continuing." : error.message || fallbackMessage, "error");
}

async function loadPending(showLoadingMessage = false) {
  if (showLoadingMessage) {
    showMessage("Loading pending review queue...", "warning");
  }

  clearFieldErrors();
  setBusy(true);

  try {
    const payload = await apiFetch("/api/admin/pending");
    renderQueue(payload);
  } catch (error) {
    setEmptyState("Unable to load pending settlements.");
    showMessage(error.message || "Unable to load pending settlements.", "error");
  }
}

async function approveCurrentItem(event) {
  event.preventDefault();

  if (!state.currentItem || state.busy) {
    return;
  }

  clearFieldErrors();
  setBusy(true);

  try {
    const payload = await apiFetch(`/api/admin/approve/${state.currentItem.id}`, {
      method: "POST",
      body: JSON.stringify(collectFormPayload()),
    });
    renderQueue(payload, `Published successfully. Data version is now ${payload.data_version}.`);
  } catch (error) {
    setBusy(false);

    if (error.status === 404) {
      showMessage("This pending item was already processed. Loading the next item...", "warning");
      await loadPending();
      return;
    }

    handleRequestError(error, "Unable to publish pending settlement.");
  }
}

async function rejectCurrentItem() {
  if (!state.currentItem || state.busy) {
    return;
  }

  clearFieldErrors();
  setBusy(true);

  try {
    const payload = await apiFetch(`/api/admin/reject/${state.currentItem.id}`, {
      method: "POST",
    });
    renderQueue(payload, "Rejected pending settlement.");
  } catch (error) {
    setBusy(false);

    if (error.status === 404) {
      showMessage("This pending item was already processed. Loading the next item...", "warning");
      await loadPending();
      return;
    }

    handleRequestError(error, "Unable to reject pending settlement.");
  }
}

elements.reviewForm.addEventListener("submit", approveCurrentItem);
elements.rejectButton.addEventListener("click", rejectCurrentItem);

setEmptyState();
loadPending(true);
