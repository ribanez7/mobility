require "spec_helper"
require "mobility/plugins/default"

describe Mobility::Plugins::Default do
  describe "when included into a class" do
    let(:default) { 'default foo' }
    let(:backend_double) { double("backend") }
    let(:backend) { backend_class.new("model", "title", default: default) }
    let(:backend_class) do
      backend_double_ = backend_double
      backend_class = Class.new(Mobility::Backends::Null) do
        define_method :read do |*args|
          backend_double_.read(*args)
        end

        define_method :write do |*args|
          backend_double_.write(*args)
        end
      end
      Class.new(backend_class).include(described_class.new(default))
    end

    describe "#read" do
      it "returns value if not nil" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return("foo")
        expect(backend.read(:fr)).to eq("foo")
      end

      it "returns value if value is false" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(false)
        expect(backend.read(:fr)).to eq(false)
      end

      it "returns default if backend return value is nil" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr)).to eq("default foo")
      end

      it "returns value of default override if passed as option to reader" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr, default: "default bar")).to eq("default bar")
      end

      it "returns nil if passed default: nil as option to reader" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr, default: nil)).to eq(nil)
      end

      it "returns false if passed default: false as option to reader" do
        expect(backend_double).to receive(:read).once.with(:fr, {}).and_return(nil)
        expect(backend.read(:fr, default: false)).to eq(false)
      end

      context "default is a Proc" do
        let(:default) { Proc.new { |attribute, locale, options| "#{attribute} in #{locale} with #{options[:this]}" } }

        it "calls default with model and attribute as args if default is a Proc" do
          expect(backend_double).to receive(:read).once.with(:fr, this: 'option').and_return(nil)
          expect(backend.read(:fr, this: 'option')).to eq("title in fr with option")
        end

        it "calls default with model and attribute as args if default option is a Proc" do
          aggregate_failures do
            # with no arguments
            expect(backend_double).to receive(:read).once.with(:fr, this: 'option').and_return(nil)
            default_as_option = Proc.new { "default" }
            expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq("default")

            # with one argument
            expect(backend_double).to receive(:read).once.with(:fr, this: 'option').and_return(nil)
            default_as_option = Proc.new { |attribute| "default #{attribute}" }
            expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq("default title")

            # with two arguments
            expect(backend_double).to receive(:read).once.with(:fr, this: 'option').and_return(nil)
            default_as_option = Proc.new { |attribute, locale| "default #{attribute} #{locale}" }
            expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq("default title fr")

            # with three arguments
            expect(backend_double).to receive(:read).once.with(:fr, this: 'option').and_return(nil)
            default_as_option = Proc.new { |attribute, locale, options| "default #{attribute} #{locale} #{options[:this]}" }
            expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq("default title fr option")

            # with any arguments
            expect(backend_double).to receive(:read).once.with(:fr, this: 'option').and_return(nil)
            default_as_option = Proc.new { |attribute, **| "default #{attribute}" }
            expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq("default title")
          end
        end

        # TODO: Remove in v1.0
        it "emits warning if proc takes keyword arguments" do
          expect(backend_double).to receive(:read).once.with(:fr, this: 'option').and_return(nil)
          default_as_option = Proc.new { |model:, attribute:, locale:, options:|  "default #{model} #{attribute} #{locale} #{options[:this]}" }
          expect {
            expect(backend.read(:fr, default: default_as_option, this: 'option')).to eq("default model title fr option")
          }.to output(/#{%{
WARNING: Passing keyword arguments to a Proc in the Default plugin is
deprecated. See the API documentation for details.}}/).to_stderr
        end
      end
    end
  end

  describe ".apply" do
    it "includes instance of default into backend class" do
      backend_class = double("backend class")
      attributes = instance_double(Mobility::Attributes, backend_class: backend_class)
      default = instance_double(described_class)

      expect(described_class).to receive(:new).with("default").and_return(default)
      expect(backend_class).to receive(:include).with(default)
      described_class.apply(attributes, "default")
    end
  end
end
