require "test_helper"

class Byomailer::TopicsTest < Byomailer::TestCase
  TOPIC = { id: 7, list_id: 3, name: "Product news", description: nil }.freeze

  def test_list_has_no_pages
    stub_api(:get, "/lists/3/topics").to_return(json(data: [ TOPIC ]))

    assert_equal [ "Product news" ], client.topics.list(list: 3).map(&:name)
  end

  def test_create
    stub_api(:post, "/lists/3/topics").with(body: { name: "Product news", description: "Launches" })
      .to_return(json({ data: TOPIC }, status: 201))

    assert_equal 7, client.topics.create(list: 3, name: "Product news", description: "Launches").id
  end

  def test_update_sends_the_name_and_the_description
    stub = stub_api(:patch, "/lists/3/topics/7").with(body: { name: "Launches", description: nil }).to_return(json(data: TOPIC))

    client.topics.update(7, list: 3, name: "Launches")

    assert_requested stub
  end

  def test_delete
    stub = stub_api(:delete, "/lists/3/topics/7").to_return(no_content)

    client.topics.delete(7, list: 3)

    assert_requested stub
  end
end
