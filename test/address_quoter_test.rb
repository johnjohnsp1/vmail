require 'test_helper'
require 'vmail/address_quoter'

class AddressQuoterTest < MiniTest::Unit::TestCase
  include Vmail::AddressQuoter

  def setup
    @string = "Bob Smith <bobsmith@gmail.com>, Jones, Rich A. <richjones@gmail.com>"
    @expected = '"Bob Smith" <bobsmith@gmail.com>, "Jones, Rich A." <richjones@gmail.com>'
    @string2 = "Jones, Rich A. <richjones@gmail.com>, Bob Smith <bobsmith@gmail.com>"
    @expected2 = '"Jones, Rich A." <richjones@gmail.com>, "Bob Smith" <bobsmith@gmail.com>'
  end

  def test_quoting
    assert_equal @expected, quote_addresses(@string)  #=> "Bob Smith" <bobsmith@gmail.com>, "Jones, Rich A." <richjones@gmail.com>
    assert_equal @expected2, quote_addresses(@string2)  #=> "Bob Smith" <bobsmith@gmail.com>, "Jones, Rich A." <richjones@gmail.com>
  end

end