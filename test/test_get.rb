# frozen_string_literal: true

require "test_helper"

class TestGet < Minitest::Test
    def test_get_is_module
        assert_equal true, Get.is_module?
    end
end
