# Rails 7.2 adds autocomplete="off" to framework-generated hidden inputs.
# The current HTML standard does not allow the on/off keywords on hidden fields.
module ValidHiddenFieldMarkup
  def tag(name = nil, options = nil, open = false, escape = true)
    if name.to_s == "input" && options.present?
      type = options[:type] || options["type"]
      autocomplete = options[:autocomplete] || options["autocomplete"]

      if type.to_s == "hidden" && autocomplete.to_s.in?(%w[on off])
        options = options.except(:autocomplete, "autocomplete")
      end
    end

    super
  end
end

ActiveSupport.on_load(:action_view) do
  prepend ValidHiddenFieldMarkup
end
