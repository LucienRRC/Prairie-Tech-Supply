require "test_helper"

class ProvinceTest < ActiveSupport::TestCase
  test "seed data includes all Canadian provinces and territories with current tax rates" do
    load Rails.root.join("db/seeds.rb")

    expected_rates = {
      "AB" => [0.05, 0, 0],
      "BC" => [0.05, 0.07, 0],
      "MB" => [0.05, 0.07, 0],
      "NB" => [0, 0, 0.15],
      "NL" => [0, 0, 0.15],
      "NT" => [0.05, 0, 0],
      "NS" => [0, 0, 0.14],
      "NU" => [0.05, 0, 0],
      "ON" => [0, 0, 0.13],
      "PE" => [0, 0, 0.15],
      "QC" => [0.05, 0.09975, 0],
      "SK" => [0.05, 0.06, 0],
      "YT" => [0.05, 0, 0]
    }

    provinces = Province.where(abbreviation: expected_rates.keys).index_by(&:abbreviation)
    assert_equal 13, provinces.size

    expected_rates.each do |abbreviation, rates|
      province = provinces.fetch(abbreviation)
      assert_equal rates.map { |rate| BigDecimal(rate.to_s) },
        [province.gst_rate, province.pst_rate, province.hst_rate],
        "Unexpected tax rates for #{province.name}"
    end
  end

  test "tax rates must be percentages between zero and one" do
    province = Province.new(name: "Invalid Tax Province", abbreviation: "IT")

    province.gst_rate = -0.01
    province.pst_rate = 1.01
    province.hst_rate = 0

    assert_not province.valid?
    assert_includes province.errors[:gst_rate], "must be greater than or equal to 0"
    assert_includes province.errors[:pst_rate], "must be less than or equal to 1"
  end
end
