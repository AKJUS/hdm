require 'test_helper'

class HieraDataTest < ActiveSupport::TestCase
  test "create for environment" do
    assert HieraData.new('development')
  end

  test "raise error for unknown environment" do
    err = assert_raises(HieraData::EnvironmentNotFound) { HieraData.new('unknown') }
    assert_match("Environment 'unknown' does not exist", err.message)
  end

  test "#search_key returns key data for all given files" do
    hiera = HieraData.new('development')
    datadir = hiera.hierarchies.first.datadir
    expected_result = {
      "nodes/testhost.yaml" => {file_present: true,  key_present: true, value: "hostname: hostname\n"},
      "role/hdm_test-development.yaml" => {file_present: false,  key_present: false, value: nil},
      "role/hdm_test.yaml" => {file_present: true, key_present: true, value: "hostname: hostname-role\n"},
      "zone/internal.yaml" => {file_present: false, key_present: false, value: nil },
      "common.yaml" => {file_present: true,  key_present: true, value: "hostname: common::hostname\n"}
    }

    result = hiera.search_key(datadir, expected_result.keys, 'psick::firstrun::linux_classes')
    assert_equal expected_result, result
  end

  test "#all_keys return all keys" do
    hiera = HieraData.new('development')
    expected_result = [
        "hdm::float", "hdm::integer", "noop_mode", "psick::enable_firstrun", "psick::firstrun::linux_classes", "psick::postfix::tp::resources_hash", "psick::time::servers", "psick::timezone"
    ]

    node = Node.new(hostname: "testhost", environment: "development")
    result = hiera.all_keys(node.facts)
    assert_equal expected_result, result
  end

  test "#write_key goes fine for the first one" do
    path = Rails.root.join('test', 'fixtures', 'files', 'puppet', 'environments', 'development', 'data', 'nodes', 'writehost.yaml')

    with_temp_file(path) do
      expected_hash = {"test_key"=>"true"}
      hiera = HieraData.new('development')
      hiera.write_key("Eyaml hierarchy", 'nodes/writehost.yaml', 'test_key', 'true')
      assert_equal expected_hash, YAML.load(File.read(path))
    end
  end

  test "#write_key goes fine for the second one" do
    path = Rails.root.join('test', 'fixtures', 'files', 'puppet', 'environments', 'development', 'data', 'nodes', 'writehost.yaml')

    with_temp_file(path) do
      expected_hash = {"abc" => "def", "test_key"=>"true"}
      hiera = HieraData.new('development')
      hiera.write_key("Eyaml hierarchy", 'nodes/writehost.yaml', 'test_key', 'true')
      hiera.write_key("Eyaml hierarchy", 'nodes/writehost.yaml', 'abc', 'def')
      assert_equal expected_hash, YAML.load(File.read(path))
    end
  end

  test "#remove_key goes fine" do
    path = Rails.root.join('test', 'fixtures', 'files', 'puppet', 'environments', 'development', 'data', 'nodes', 'writehost.yaml')

    with_temp_file(path) do
      expected_hash = {}
      hiera = HieraData.new('development')
      hiera.remove_key("Eyaml hierarchy", 'nodes/writehost.yaml', 'test_key')
      assert_equal expected_hash, YAML.load(File.read(path))
    end
  end
end
