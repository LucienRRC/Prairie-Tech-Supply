document.addEventListener("DOMContentLoaded", () => {
  const cart = document.querySelector("[data-session-cart]");
  if (!cart) return;

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
      status.textContent = "Saving…";

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
});
