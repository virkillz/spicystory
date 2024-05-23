defmodule Eroticlone.ContentTest do
  use Eroticlone.DataCase

  alias Eroticlone.Content

  describe "stories" do
    alias Eroticlone.Content.Story

    import Eroticlone.ContentFixtures

    @invalid_attrs %{author: nil, category: nil, content: nil, link: nil, rating: nil, status: nil, title: nil}

    test "list_stories/0 returns all stories" do
      story = story_fixture()
      assert Content.list_stories() == [story]
    end

    test "get_story!/1 returns the story with given id" do
      story = story_fixture()
      assert Content.get_story!(story.id) == story
    end

    test "create_story/1 with valid data creates a story" do
      valid_attrs = %{author: "some author", category: "some category", content: "some content", link: "some link", rating: 120.5, status: "some status", title: "some title"}

      assert {:ok, %Story{} = story} = Content.create_story(valid_attrs)
      assert story.author == "some author"
      assert story.category == "some category"
      assert story.content == "some content"
      assert story.link == "some link"
      assert story.rating == 120.5
      assert story.status == "some status"
      assert story.title == "some title"
    end

    test "create_story/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_story(@invalid_attrs)
    end

    test "update_story/2 with valid data updates the story" do
      story = story_fixture()
      update_attrs = %{author: "some updated author", category: "some updated category", content: "some updated content", link: "some updated link", rating: 456.7, status: "some updated status", title: "some updated title"}

      assert {:ok, %Story{} = story} = Content.update_story(story, update_attrs)
      assert story.author == "some updated author"
      assert story.category == "some updated category"
      assert story.content == "some updated content"
      assert story.link == "some updated link"
      assert story.rating == 456.7
      assert story.status == "some updated status"
      assert story.title == "some updated title"
    end

    test "update_story/2 with invalid data returns error changeset" do
      story = story_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_story(story, @invalid_attrs)
      assert story == Content.get_story!(story.id)
    end

    test "delete_story/1 deletes the story" do
      story = story_fixture()
      assert {:ok, %Story{}} = Content.delete_story(story)
      assert_raise Ecto.NoResultsError, fn -> Content.get_story!(story.id) end
    end

    test "change_story/1 returns a story changeset" do
      story = story_fixture()
      assert %Ecto.Changeset{} = Content.change_story(story)
    end
  end

  describe "pages" do
    alias Eroticlone.Content.Page

    import Eroticlone.ContentFixtures

    @invalid_attrs %{content: nil, page: nil}

    test "list_pages/0 returns all pages" do
      page = page_fixture()
      assert Content.list_pages() == [page]
    end

    test "get_page!/1 returns the page with given id" do
      page = page_fixture()
      assert Content.get_page!(page.id) == page
    end

    test "create_page/1 with valid data creates a page" do
      valid_attrs = %{content: "some content", page: 42}

      assert {:ok, %Page{} = page} = Content.create_page(valid_attrs)
      assert page.content == "some content"
      assert page.page == 42
    end

    test "create_page/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_page(@invalid_attrs)
    end

    test "update_page/2 with valid data updates the page" do
      page = page_fixture()
      update_attrs = %{content: "some updated content", page: 43}

      assert {:ok, %Page{} = page} = Content.update_page(page, update_attrs)
      assert page.content == "some updated content"
      assert page.page == 43
    end

    test "update_page/2 with invalid data returns error changeset" do
      page = page_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_page(page, @invalid_attrs)
      assert page == Content.get_page!(page.id)
    end

    test "delete_page/1 deletes the page" do
      page = page_fixture()
      assert {:ok, %Page{}} = Content.delete_page(page)
      assert_raise Ecto.NoResultsError, fn -> Content.get_page!(page.id) end
    end

    test "change_page/1 returns a page changeset" do
      page = page_fixture()
      assert %Ecto.Changeset{} = Content.change_page(page)
    end
  end
end
