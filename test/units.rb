require 'minitest/autorun'
require 'units'

describe Units do
    describe "when validating strings" do
	let(:units_s)   { Units::UNITS.map {|u| (u.to_s + 's').to_sym } }
	let(:units_es)  { Units::UNITS.map {|u| (u.to_s + 'es').to_sym } }
	
	it "should accept all valid units" do
	    Units::UNITS.each {|unit| Units.valid_unit?(unit).must_equal(true) }
	end

	it "should accept all valid plural units" do
	    (units_s + units_es).each {|u| Units.valid_unit?(u).must_equal(true) }
	end

	it "should accept all valid prefixed units" do
	    all = Units::UNITS.map {|u| Units::PREFIXES.keys.map {|p| p.to_s + u.to_s } }
	    all.flatten.each {|u| Units.valid_unit?(u.to_sym).must_equal(true) }
	end

	it "should accept all valid abbreviations" do
	    Units::ABBREVIATIONS.keys.each {|a| Units.valid_unit?(a).must_equal(true) }
	end
	
	it "reject invalid units" do
	    Units.valid_unit?(:foo).wont_equal(true)
	end

	it "reject invalid prefix" do
	    Units.valid_unit?(:foometer).wont_equal(true)
	end
    end

    describe "when constructing" do
	let(:meter_hash) { {:meters => 1} }
	let(:meter_inch_hash) { {:meters => 1, :inches => 1} } 

	it "should accept valid units hash" do
	    Units.new(:meter_hash).must_equal Units.new(:meters => 1)
	end

	it "should accept valid units hashification" do
	    Units.new(:meters => 1, :inches => 1).must_equal Units.new(meter_inch_hash)
	end
	
	it "should accept valid units arrayification" do
	    Units.new(:meters, :inches).must_equal Units.new(meter_inch_hash)
	end

	it "should accept valid units strings" do
	    Units::UNITS.each {|unit| Units.new(unit.to_s).must_equal Units.new({unit => 1}) }
	end

	it "should accept valid units symbols with unitary exponents" do
	    Units::UNITS.each {|unit| Units.new(unit).must_equal Units.new({unit => 1}) }
	end
	
	it "should reject nil units" do
	    lambda { Units.new(nil) }.must_raise(ArgumentError)
	end

	it "should reject a units hash with zeroed exponents" do
	    lambda { Units.new({:meters => 0}) }.must_raise(ArgumentError)
	    lambda { Units.new({:meters => 0, :inches => 0}) }.must_raise(ArgumentError)
	end

	it "should reject an empty units hash" do
	    lambda { Units.new({}) }.must_raise(ArgumentError)
	end

	it "should reject a hash with invalid units" do
	    lambda { Units.new({:foo => 1}) }.must_raise(UnitsError)
	end

	it "should reject an empty string" do
	    lambda { Units.new('') }.must_raise(UnitsError)
	end

	it "should reject a string with an invalid unit" do
	    lambda { Units.new('foo') }.must_raise(UnitsError)
	end

	it "should reject an invalid units symbol" do
	    lambda { Units.new(:foo) }.must_raise(UnitsError)
	end

	it "ignore hash keys with zero value" do
	    meter = Units.new(:meters)
	    Units.new(:meters => 1, :inches => 0).must_equal meter
	    Units.new(:meters => 1, :inches => 1).wont_equal meter
	end

	it "must have a convenience method for instantiating units" do
	    Units.meter.must_equal Units.new(:meters)
	    Units.mm.must_equal Units.new(:millimeters)
	end
    end

    describe "equality" do
	let(:meter) { Units.new(:meters) }
	let(:inch) { Units.new(:inch) }

	it "equal units must be equal" do
	    meter.must_equal meter
	end

	it "unequal units must be unequal" do
	    meter.wont_equal inch
	end
	
	it "should preserve case equality" do
	    (meter === meter).must_equal true
	    (meter === inch).wont_equal true
	    (inch === meter).wont_equal true
	end
	
	it "should not equal nil" do
	    meter.wont_be_nil
	end
    end

    describe 'arithmetic with like units' do
	it 'must exponentiate' do
	    (Units.meters**2).must_equal Units.new(meters:2)
	end
    end

    describe "arithmetic with mixed units" do
	let(:meter) { Units.new(:meters) }

	it "should multiply" do
	    (meter * Units.new(:inches)).must_equal Units.new(:meters => 1, :inches => 1)
	end
	
	it "should multiply by nil" do
	    (meter * nil).must_equal meter
	end
	
	it "should divide by nil" do
	    (meter / nil).must_equal meter
	end
    end

    describe "comparison" do
	describe "spaceship" do
	    it "must return 0 for equal units" do
		(Units.new(:meters) <=> Units.new(:meters)).must_equal 0
	    end

	    it "must return nil for unequal units" do
		(Units.new(:meters) <=> Units.new(:inches)).must_be_nil
	    end
	end
    end

    describe "conversion" do
	it "should have an inspect method" do
	    Units.new('meters').inspect.must_equal 'meter'
	end
	
	it "should have a to_s method" do
	    Units.new('meters').to_s.must_equal 'meter'
	end
	
	it "should have a to_abbreviation method" do
	    Units.new('centimeters').to_abbreviation.must_equal 'cm'
	end

	it "must have a convert method that converts a value to new units" do
	    Units.meter.convert(10, 'inch').must_equal 393.701
	end

	it 'must convert degrees to radians' do
	    90.degrees.radians.must_be_close_to Math::PI/2
	end
    end

    it "must square root" do
	(Units.new('meters')*Units.new('meters')).square_root.must_equal Units.new('meters')
    end

    describe 'when converting to other units with the per_ prefix' do
	it 'must add the correct units to existing units' do
	    Units.new('meters').per(:second).must_equal Units.new({meter:1, second:-1})
	    Units.new('meters').per(second:2).must_equal Units.new({meter:1, second:-2})

	    Units.new('meters').per('second').must_equal Units.new({meter:1, second:-1})
	    Units.new('meters').per('second' => 2).must_equal Units.new({meter:1, second:-2})
	end

	it 'must cancel units when appropriate' do
	    Units.new(second:2).per(:second).must_equal Units.new(:second)
	    Units.new('second').per(:second).must_equal nil
	end
    end

    describe 'when checking conversion validity' do
	it 'must accept inches and meters' do
	    Units.meter.valid_conversion?('inch').must_equal true
	    Units.inch.valid_conversion?('meter').must_equal true
	    Units.meter.valid_conversion?(:inch).must_equal true
	    Units.inch.valid_conversion?(:meter).must_equal true
	end

	it 'must accept conversion to self' do
	    Units.meter.valid_conversion?(:meter).must_equal true
	    Units.meter.valid_conversion?(:mm).must_equal true
	end

	it 'must accept mixed prefixes' do
	    Units.inch.valid_conversion?(:mm).must_equal true
	end

	it 'must reject nonsense conversions' do
	    Units.meter.valid_conversion?(:foo).must_equal false
	end

	it 'must reject invalid conversions' do
	    Units.meter.valid_conversion?(:hertz).must_equal nil
	end
    end

    describe 'when overriding is_a?' do
	it 'must be a base unit' do
	    Units.meters.is_a?(:meters).must_equal true
	end

	it 'must be a prefixed unit' do
	    Units.mm.is_a?(:meters).must_equal true
	end
    end
end
