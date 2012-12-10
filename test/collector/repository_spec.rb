require File.expand_path("../../test_helper.rb", __FILE__)

describe Collector::Repository do

  before do
    Object.send(:remove_const, :TestRepository) if Object.const_defined?(:TestRepository)
    class TestRepository
      include Collector::Repository
    end
  end

  it "has a model derived from its class name" do
    TestRepository.model.name.must_equal "Test"
  end

  it "has a collection_name derived from its model" do
    TestRepository.collection_name.must_equal "tests"
  end

  describe "collection" do
    describe "when a connection is set" do
      it "returns the mongo collection" do
        collection = mock()
        connection = mock { stubs(:[]).with("tests").returns(collection) }
        Collector.stubs(:connection).returns(connection)

        TestRepository.collection.must_equal collection
      end
    end
  end

  describe "save" do
    it "touches the model and then saves it" do
      model = mock(:touch)
      TestRepository.expects(:save_without_updating_timestamps).with(model)
      TestRepository.save(model)
    end
  end

  describe "save_without_updating_timestamps" do
    it "serializes the model and then inserts it into the collection" do
      model = stub()
      TestRepository.expects(:serialize!).with(model).returns({ foo: "bar" })

      collection = mock(insert: { foo: "bar" })
      TestRepository.stubs(:collection).returns(collection)

      TestRepository.save_without_updating_timestamps(model)
    end
  end

  describe "serialize!" do
    it "normalize id to _id" do
      model = mock(attributes: { id: 123, foo: "bar" })
      TestRepository.serialize!(model).must_equal({ "_id" => 123, "foo" => "bar" })
    end

    it "returns a model's attributes without nil values" do
      model = mock(attributes: { foo: "bar", nothing: nil })
      TestRepository.serialize!(model).must_equal({ "foo" => "bar" })
    end
  end

  describe "serialize" do
    it "returns a model's attributes" do
      model = mock(attributes: { foo: "bar" })
      TestRepository.serialize(model).must_equal({ "foo" => "bar" })
    end
  end

  describe "deserialize!" do
    it "normalizes _id to id" do
      TestRepository.expects(:deserialize).with("id" => 123, "name" => "Brandon")
      TestRepository.deserialize!(_id: 123, name: "Brandon")
    end
  end

  describe "deserialize" do
    it "instantiates a new model from a hash of attributes" do
      attributes = { first_name: "Brandon", last_name: "Weiss" }
      TestRepository.model.expects(:new).with(attributes)
      TestRepository.deserialize(attributes)
    end
  end

  describe "find_by" do
    it "finds documents by a hash of attributes" do
      document_1 = stub
      document_2 = stub
      documents  = [document_1, document_2]
      TestRepository.expects(:deserialize!).with(document_1)
      TestRepository.expects(:deserialize!).with(document_2)
      collection = mock { expects(:find).with(attribute: "value").returns(documents) }
      TestRepository.expects(:collection).returns(collection)
      TestRepository.find_by(attribute: "value")
    end

    it "finds all documents if no attributes are given" do
      document_1 = stub
      document_2 = stub
      documents  = [document_1, document_2]
      TestRepository.expects(:deserialize!).with(document_1)
      TestRepository.expects(:deserialize!).with(document_2)
      collection = mock { expects(:find).with({}).returns(documents) }
      TestRepository.expects(:collection).returns(collection)
      TestRepository.find_by
    end
  end

  describe "find_first_by" do
    it "finds the first document by a hash of attributes" do
      TestRepository.expects(:find_by).with(attribute: "value").returns(mock(:first))
      TestRepository.find_first_by(attribute: "value")
    end
  end

  describe "all" do
    it "finds by attributes without any attributes" do
      TestRepository.expects(:find_by).with()
      TestRepository.all
    end
  end

  describe "find_by_id" do
    it "finds by id" do
      TestRepository.expects(:find_by).with(_id: "bson-id")
      TestRepository.find_by_id("bson-id")
    end
  end

  describe "find_first_by_id" do
    it "finds first by id" do
      TestRepository.expects(:find_first_by).with(_id: "bson-id")
      TestRepository.find_first_by_id("bson-id")
    end
  end

  describe "dynamic finders" do
    it "dynamically matches find_by_ finders" do
      TestRepository.expects(:find_by).with(email: "foobar@fibroblast.com")
      TestRepository.find_by_email("foobar@fibroblast.com")
    end

    it "dynamically matches find_first_by_ finders" do
      TestRepository.expects(:find_first_by).with(email: "foobar@fibroblast.com")
      TestRepository.find_first_by_email("foobar@fibroblast.com")
    end

    it "responds to dynamically matched find_by_ finders" do
      TestRepository.respond_to?(:find_by_email).must_equal true
    end

    it "responds to dynamically matched find_first_by_ finders" do
      TestRepository.respond_to?(:find_first_by_email).must_equal true
    end
  end

end
