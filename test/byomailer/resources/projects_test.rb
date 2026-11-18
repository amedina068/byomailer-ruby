require "test_helper"

class Byomailer::ProjectsTest < Byomailer::TestCase
  PROJECT = { id: 2, name: "Launch", newsletters_count: 3 }.freeze

  def test_list
    stub_api(:get, "/projects").to_return(cursor_page([ PROJECT ]))

    assert_equal [ "Launch" ], client.projects.list.map(&:name)
  end

  def test_find
    stub_api(:get, "/projects/2").to_return(json(data: PROJECT))

    assert_equal 3, client.projects.find(2).newsletters_count
  end

  def test_create
    stub_api(:post, "/projects").with(body: { name: "Launch" }).to_return(json({ data: PROJECT }, status: 201))

    assert_equal 2, client.projects.create(name: "Launch").id
  end

  def test_rename
    stub_api(:patch, "/projects/2").with(body: { name: "Relaunch" }).to_return(json(data: PROJECT.merge(name: "Relaunch")))

    assert_equal "Relaunch", client.projects.rename(2, name: "Relaunch").name
  end

  def test_delete
    stub = stub_api(:delete, "/projects/2").to_return(no_content)

    client.projects.delete(2)

    assert_requested stub
  end
end
