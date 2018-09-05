require 'test_helper'

class EdamControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should filter topics' do
    get :topics, params: { filter: 'metab', format: :json }
    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 1, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Metabolomics'
  end

  test 'should filter operations' do
    get :operations, params: { filter: 'metab', format: :json }
    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 2, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Metabolic network modelling'
  end

  test 'should filter all terms' do
    get :terms, params: { filter: 'rna', format: :json }
    assert_response :success

    res = JSON.parse(response.body)
    assert_equal 14, res.length
    labels = res.map { |t| t['preferred_label'] }
    uris = res.map { |t| t['uri'] }
    assert_includes labels, 'RNA splicing'
    assert_includes uris, 'http://edamontology.org/topic_3523'
    assert_includes uris, 'http://edamontology.org/operation_3563'
  end

  test 'should filter multiple times' do
    get :terms, params: { filter: 'data', format: :json }
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 16, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Database management'

    get :terms, params: { filter: 'xylophone', format: :json }
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 0, res.length

    get :terms, params: { filter: 'data', format: :json }
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 16, res.length
    assert_includes res.map { |t| t['preferred_label'] }, 'Database management'
  end

  test 'should filter out deprecated terms' do
    # <EDAM::Term @ontology=EDAM::OldOntology, @uri=http://edamontology.org/operation_0467, label: Protein secondary structure prediction (integrated)>
    # <EDAM::Term @ontology=EDAM::OldOntology, @uri=http://edamontology.org/operation_0421, label: Protein folding site prediction>
    # <EDAM::Term @ontology=EDAM::OldOntology, @uri=http://edamontology.org/operation_3088, label: Protein property calculation (from sequence)>
    # <EDAM::Term @ontology=EDAM::OldOntology, @uri=http://edamontology.org/operation_2506, label: Protein sequence alignment analysis>
    deprecated_protein_operation_uris = %w(
    http://edamontology.org/operation_0467
    http://edamontology.org/operation_0421
    http://edamontology.org/operation_3088
    http://edamontology.org/operation_2506)

    deprecated_protein_operation_uris.each do |uri|
      term = EDAM::Ontology.instance.lookup(uri)
      assert term, "#{uri} should be present in EDAM ontology"
      assert term.deprecated?, "#{uri} should be flagged as deprecated in EDAM ontology"
    end

    get :operations, params: { filter: 'Protein ', format: :json }
    assert_response :success
    res = JSON.parse(response.body)
    uris = res.map { |t| t['uri'] }
    refute (uris & deprecated_protein_operation_uris).any?, "Response should not contain any deprecated URIs"
  end
end
