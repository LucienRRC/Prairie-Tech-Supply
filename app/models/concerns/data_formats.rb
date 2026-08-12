module DataFormats
  NAME = /\A[\p{L}][\p{L}\p{M}'’ .-]*\z/
  EMAIL = /\A[^@\s]+@(?:[a-z0-9-]+\.)+[a-z]{2,63}\z/i
  PHONE = /\A(?:\+?1[ .-]?)?(?:\(\d{3}\)|\d{3})[ .-]?\d{3}[ .-]?\d{4}\z/
  CANADIAN_POSTAL_CODE = /\A[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z][ -]?\d[ABCEGHJ-NPRSTV-Z]\d\z/i
  SKU = /\A[A-Z0-9]+(?:-[A-Z0-9]+)*\z/
  STRIPE_CHECKOUT_SESSION_ID = /\Acs_(?:test|live)_[A-Za-z0-9_]+\z/
  STRIPE_PAYMENT_INTENT_ID = /\Api_(?:test|live)_[A-Za-z0-9_]+\z/
end
