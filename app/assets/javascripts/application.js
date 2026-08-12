const initializeNavigation = () => {
  const toggle = document.querySelector(".nav-toggle");
  const navigation = document.querySelector("#site-navigation");
  if (!toggle || !navigation || toggle.dataset.initialized === "true") return;

  toggle.dataset.initialized = "true";
  document.body.classList.add("nav-ready");

  const setOpen = (open) => {
    toggle.setAttribute("aria-expanded", String(open));
    toggle.setAttribute("aria-label", open ? "Close main navigation" : "Open main navigation");
    navigation.classList.toggle("is-open", open);
  };

  toggle.addEventListener("click", () => {
    setOpen(toggle.getAttribute("aria-expanded") !== "true");
  });

  navigation.addEventListener("click", (event) => {
    if (event.target.closest("a, button") && window.matchMedia("(max-width: 900px)").matches) {
      setOpen(false);
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && toggle.getAttribute("aria-expanded") === "true") {
      setOpen(false);
      toggle.focus();
    }
  });

  window.matchMedia("(min-width: 901px)").addEventListener("change", (event) => {
    if (event.matches) setOpen(false);
  });
};

const initializeCart = () => {
  const cart = document.querySelector("[data-session-cart]");
  if (!cart || cart.dataset.initialized === "true") return;

  cart.dataset.initialized = "true";
  const currency = new Intl.NumberFormat("en-CA", {
    style: "currency",
    currency: "CAD"
  });
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
  const forms = Array.from(cart.querySelectorAll("[data-auto-cart-form]"));
  const subtotal = cart.querySelector("[data-cart-subtotal]");
  const itemCount = cart.querySelector("[data-cart-item-count]");
  const navigationCount = document.querySelector(".cart-count");

  const normalizedQuantity = (input) => {
    const minimum = Number(input.min || 1);
    const maximum = Number(input.max || Number.MAX_SAFE_INTEGER);
    const requested = Number.parseInt(input.value, 10);
    return Math.min(Math.max(Number.isNaN(requested) ? minimum : requested, minimum), maximum);
  };

  const renderTotals = () => {
    let quantityTotal = 0;
    let priceTotal = 0;

    forms.forEach((form) => {
      const input = form.querySelector("input[name='quantity']");
      const quantity = normalizedQuantity(input);
      const lineTotal = quantity * Number(form.dataset.unitPrice);

      input.value = quantity;
      quantityTotal += quantity;
      priceTotal += lineTotal;
      form.closest(".cart-item")
        .querySelector("[data-line-total]").textContent = currency.format(lineTotal);
    });

    subtotal.textContent = currency.format(priceTotal);
    itemCount.textContent = `${quantityTotal} ${quantityTotal === 1 ? "item" : "items"} in your cart`;
    navigationCount.textContent = quantityTotal;
  };

  forms.forEach((form) => {
    const input = form.querySelector("input[name='quantity']");
    const status = form.querySelector("[data-save-status]");
    let saveTimer;

    input.addEventListener("input", () => {
      window.clearTimeout(saveTimer);
      renderTotals();
      status.textContent = "Saving...";

      saveTimer = window.setTimeout(async () => {
        try {
          const response = await fetch(form.action, {
            method: "PATCH",
            headers: {
              "Accept": "application/json",
              "X-CSRF-Token": csrfToken
            },
            body: new FormData(form)
          });

          if (!response.ok) throw new Error("Cart update failed");

          const result = await response.json();
          input.value = result.quantity;
          form.closest(".cart-item")
            .querySelector("[data-line-total]").textContent = currency.format(result.line_total);
          subtotal.textContent = currency.format(result.subtotal);
          itemCount.textContent = `${result.item_count} ${result.item_count === 1 ? "item" : "items"} in your cart`;
          navigationCount.textContent = result.item_count;
          status.textContent = "Saved";
        } catch (_error) {
          status.textContent = "Could not save. Try again.";
        }
      }, 350);
    });
  });
};

const initializeCheckoutTaxPreview = () => {
  const review = document.querySelector("[data-checkout-review]");
  const provinceSelect = document.querySelector("[data-checkout-province]");
  if (!review || !provinceSelect || review.dataset.initialized === "true") return;

  review.dataset.initialized = "true";
  const subtotal = Number(review.dataset.subtotal);
  const breakdown = review.querySelector("[data-checkout-tax-breakdown]");
  const prompt = review.querySelector("[data-tax-prompt]");
  const totalOutput = review.querySelector("[data-checkout-total]");
  const currency = new Intl.NumberFormat("en-CA", {
    style: "currency",
    currency: "CAD"
  });

  const roundedAmount = (amount) => Math.round((amount + Number.EPSILON) * 100) / 100;
  const formattedRate = (rate) => `${Number((rate * 100).toFixed(3))}%`;

  const renderTaxPreview = () => {
    const option = provinceSelect.selectedOptions[0];
    const hasProvince = Boolean(option?.value);

    breakdown.hidden = !hasProvince;
    prompt.hidden = hasProvince;
    if (!hasProvince) return;

    let taxTotal = 0;
    ["gst", "pst", "hst"].forEach((taxName) => {
      const rate = Number(option.dataset[`${taxName}Rate`] || 0);
      const amount = roundedAmount(subtotal * rate);
      const row = review.querySelector(`[data-tax-row="${taxName}"]`);

      row.hidden = rate <= 0;
      review.querySelector(`[data-tax-rate="${taxName}"]`).textContent = `(${formattedRate(rate)})`;
      review.querySelector(`[data-tax-amount="${taxName}"]`).textContent = currency.format(amount);
      taxTotal += amount;
    });

    totalOutput.textContent = currency.format(roundedAmount(subtotal + taxTotal));
  };

  provinceSelect.addEventListener("change", renderTaxPreview);
  renderTaxPreview();
};

document.addEventListener("DOMContentLoaded", () => {
  initializeNavigation();
  initializeCart();
  initializeCheckoutTaxPreview();
});

document.addEventListener("turbo:load", () => {
  initializeNavigation();
  initializeCart();
  initializeCheckoutTaxPreview();
});
