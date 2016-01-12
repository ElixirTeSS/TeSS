require 'test_helper'

class ScientificTopicsControllerTest < ActionController::TestCase
  setup do
    @scientific_topic = scientific_topics(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scientific_topics)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scientific_topic" do
    assert_difference('ScientificTopic.count') do
      post :create, scientific_topic: { consider: @scientific_topic.consider, created_in: @scientific_topic.created_in, definitions: @scientific_topic.definitions, documentation: @scientific_topic.documentation, has_alternative_id: @scientific_topic.has_alternative_id, has_broad_synonym: @scientific_topic.has_broad_synonym, has_dbxref: @scientific_topic.has_dbxref, has_definition: @scientific_topic.has_definition, has_exact_synonym: @scientific_topic.has_exact_synonym, has_related_synonym: @scientific_topic.has_related_synonym, has_subset: @scientific_topic.has_subset, obsolete: @scientific_topic.obsolete, obsolete_since: @scientific_topic.obsolete_since, parents: @scientific_topic.parents, preferred_label: @scientific_topic.preferred_label, prefix_iri: @scientific_topic.prefix_iri, replaced_by: @scientific_topic.replaced_by, saved_by: @scientific_topic.saved_by, subset_property: @scientific_topic.subset_property, synonyms: @scientific_topic.synonyms }
    end

    assert_redirected_to scientific_topic_path(assigns(:scientific_topic))
  end

  test "should show scientific_topic" do
    get :show, id: @scientific_topic
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @scientific_topic
    assert_response :success
  end

  test "should update scientific_topic" do
    patch :update, id: @scientific_topic, scientific_topic: { consider: @scientific_topic.consider, created_in: @scientific_topic.created_in, definitions: @scientific_topic.definitions, documentation: @scientific_topic.documentation, has_alternative_id: @scientific_topic.has_alternative_id, has_broad_synonym: @scientific_topic.has_broad_synonym, has_dbxref: @scientific_topic.has_dbxref, has_definition: @scientific_topic.has_definition, has_exact_synonym: @scientific_topic.has_exact_synonym, has_related_synonym: @scientific_topic.has_related_synonym, has_subset: @scientific_topic.has_subset, obsolete: @scientific_topic.obsolete, obsolete_since: @scientific_topic.obsolete_since, parents: @scientific_topic.parents, preferred_label: @scientific_topic.preferred_label, prefix_iri: @scientific_topic.prefix_iri, replaced_by: @scientific_topic.replaced_by, saved_by: @scientific_topic.saved_by, subset_property: @scientific_topic.subset_property, synonyms: @scientific_topic.synonyms }
    assert_redirected_to scientific_topic_path(assigns(:scientific_topic))
  end

  test "should destroy scientific_topic" do
    assert_difference('ScientificTopic.count', -1) do
      delete :destroy, id: @scientific_topic
    end

    assert_redirected_to scientific_topics_path
  end
end
