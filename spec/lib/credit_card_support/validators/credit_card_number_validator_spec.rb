require 'active_model'
require 'spec_helper'
require 'credit_card_support/validators/credit_card_number_validator' if Object.const_defined?(:ActiveModel)

class CreditCard
  extend  ActiveModel::Naming
  extend  ActiveModel::Translation
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :number

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  def initialize(opts={})
    opts.each do |k,v|
      send(:"#{k}=", v)
    end
  end

end

class CreditCardTest < CreditCard
  validates :number,
  credit_card_number: true,
  credit_card_support: {
    allow_testcards: true,
    allow_issuers: [:visa, :master_card]
  }
end

class CreditCardWithCustomMessage < CreditCard
  validates :number,
  credit_card_number: { message: 'Luhn fail!' },
  credit_card_support: {
    allow_testcards: true,
    allow_issuers: [:visa, :master_card],
    message: "Not supported!"
  }
end

class CreditCardProduction < CreditCard
  validates :number,
  credit_card_number: true,
  credit_card_support: {
    allow_testcards: false,
    allow_issuers: [:visa, :master_card]
  }
end


describe ActiveModel::Validations::CreditCardNumberValidator do
  subject { CreditCardTest.new(number: '4012888888881881'.freeze) }

  it "is valid" do
    subject.should be_valid
  end

  describe "#number" do
    it "must exist" do
      subject.number = nil
      subject.should_not be_valid
    end
    it "must be luhn" do
      subject.number = '4012888888881882'
      subject.should_not be_valid
    end

    context "with custom card support messages" do
      subject { CreditCardWithCustomMessage.new(number: '3528000000000007') }
      it "has a custom message" do
        subject.valid?
        subject.errors[:number].first.should == 'Not supported!'
      end
    end

    context "with custom luhn calculation failure messages" do
      subject { CreditCardWithCustomMessage.new(number: '4111111111111112') }
      it "has a custom message" do
        subject.valid?
        subject.errors[:number].first.should == 'Luhn fail!'
      end
    end

    context "production" do
      subject { CreditCardProduction.new(number: '4485071359608368') }
      context "testnumber" do
        it "is invalid" do
          subject.number = '4012888888881881'
          subject.should be_invalid
        end
      end
      context "valid number" do
        it "is valid" do
          subject.should be_valid
        end
      end
    end
  end
end
