var MarkdownIt = window.markdownit();

var Workflows = {
    formSubmitted: false,

    handleClick: function (e) {
        if (Workflows.state === 'adding node') {
            Workflows.placeNode(e.cyPosition);
        } else if (Workflows.state === 'linking node') {
            if (e.cyTarget !== cy && e.cyTarget.isNode()) {
                Workflows.createLink(e);
            }
        }
    },

    setState: function (state, message) {
        Workflows.state = state;
        if (message)
            $('#workflow-status-message').html(message).show();
        var button = $('#workflow-toolbar-cancel');
        button.find('span').html('Cancel ' + state);
        button.show();
    },

    cancelState: function () {
        Workflows.state = '';

        if (Workflows.selected) {
            Workflows.selected.unselect();
            Workflows.selected = null;
        }

        $('#workflow-status-message').html('').hide();
        $('#workflow-status-selected-node').html('<span class="muted">Nothing selected</span>').attr('title', '');
        $('#workflow-status-bar').find('.node-context-button').hide();
        $('#workflow-toolbar-cancel').hide();
    },

    select: function (target) {
        if (target.isNode()) {
            Workflows.selected = target;
            Workflows.setState('node selection');
            $('#workflow-status-bar').find('.node-context-button').show();
            $('#workflow-status-selected-node').html(Workflows.selected.data('name'))
                .attr('title', Workflows.selected.data('name'));
        } else if (target.isEdge()) {
            Workflows.selected = target;
            Workflows.setState('edge selection');
            $('#workflow-status-bar').find('.edge-context-button').show();
            $('#workflow-status-selected-node').html(Workflows.selected.data('name') + ' (edge)')
                .attr('title',Workflows.selected.data('name') + ' (edge)');
        }
    },

    setAddNodeState: function () {
        Workflows.cancelState();
        Workflows.setState('adding node', 'Click on the diagram to add a new node.');
    },

    placeNode: function (position, parentId) {
        // Offset child nodes a bit so they don't stack on top of each other...
        var pos = { x: position.x, y: position.y };
        if (parentId && Workflows.selected.children().length > 0)
            pos.y = Workflows.selected.children().last().position().y + 40;

        Workflows.nodeModal.populate(parentId ? 'Add child node' : 'Add node', { parent: parentId }, pos);

        $('#node-modal').modal('show');
    },

    addNode: function () {
        var node = Workflows.nodeModal.fetch();
        $('#node-modal').modal('hide');

        Workflows.history.modify(node.data.parent ? 'add child node' : 'add node', function () {
            var newNode = cy.add(node);
            // Select the new node, or if it is a child node, select the parent.
            if (!node.data.parent) {
                newNode.select();
            } else {
                cy.$('#' + node.data.parent).select();
            }
        });
    },

    addChild: function () {
        Workflows.placeNode(Workflows.selected.position(), Workflows.selected.id());
    },

    edit: function () {
        if (Workflows.state === 'node selection') {
            Workflows.nodeModal.populate('Edit node', Workflows.selected.data(), Workflows.selected.position());
        } else if (Workflows.state === 'edge selection') {
            $('#edge-modal').modal('show');
            $('#edge-modal-form-label').val(Workflows.selected.data('name'));
        }
    },

    updateNode: function () {
        var node = Workflows.selected;

        Workflows.history.modify('edit node', function () {
            node.data(Workflows.nodeModal.fetch().data);
        });

        $('#node-modal').modal('hide');
        node.select();
    },

    updateEdge: function () {
        var edge = Workflows.selected;

        Workflows.history.modify('edit edge', function () {
            edge.data('name', $('#edge-modal-form-label').val());
        });

        $('#edge-modal').modal('hide');
        edge.select();
    },

    nodeModalConfirm: function () {
        $('#node-modal-form-id').val() ? Workflows.updateNode() : Workflows.addNode();
    },

    edgeModalConfirm: function () {
        Workflows.updateEdge();
    },

    setLinkNodeState: function () {
        Workflows.setState('linking node', 'Click on a node to create a link.');
    },

    createLink: function (e) {
        Workflows.history.modify('link', function () {
            e.cy.add({
                group: "edges",
                data: {
                    source: Workflows.selected.data('id'),
                    target: e.cyTarget.data('id')
                }
            });
        });

        Workflows.cancelState();
    },

    delete: function () {
        if (confirm('Are you sure you wish to delete this?')) {
            Workflows.history.modify('delete', function () {
                Workflows.selected.remove();
            });

            Workflows.cancelState();
        }
    },

    promptBeforeLeaving: function (e) {
        if ($("#workflow-diagram-content #cy[data-editable='true']").length > 0) {
            if (Workflows.history.index > 0 && !Workflows.formSubmitted) {
                return confirm('You have unsaved changes, are you sure you wish to leave the page?');
            } else {
                e = null;
            }
        }
    },

    storeLastSelection: function () {
        if (typeof Storage !== 'undefined') {
            var id = $('#workflow-content-json').data('tessId');
            var lastSelectedID = cy.$(':selected').id();
            if (lastSelectedID) {
                localStorage.setItem('workflow-last-selection-' + id, lastSelectedID);
            }
        }
    },

    loadLastSelection: function () {
        if (typeof Storage !== 'undefined') {
            var id = $('#workflow-content-json').data('tessId');
            var lastSelectedID = localStorage.getItem('workflow-last-selection-' + id);
            if (lastSelectedID) {
                cy.$('#' + lastSelectedID).select();
            }
        }
    },

    nodeModal: {
        populate: function (title, data, position) {
            $('#node-modal-title').html('title');
            $('#node-modal').modal('show');
            $('#node-modal-form-id').val(data.id);
            $('#node-modal-form-title').val(data.name);
            $('#node-modal-form-description').val(data.description);
            if (data.color) {
                $('#node-modal-form-colour')[0].jscolor.fromString(data.color);
            } else if (data.parent) {
                $('#node-modal-form-colour')[0].jscolor.fromString(cy.$('#' + data.parent).data('color'));
            }
            $('#node-modal-form-parent-id').val(data.parent);
            $('#node-modal-form-x').val(position.x);
            $('#node-modal-form-y').val(position.y);
            $('#term-autocomplete').val('');
            Workflows.associatedResources.populate(data.associatedResources || []);
            Workflows.ontologyTerms.populate(data.ontologyTerms || []);
        },

        fetch: function () {
            return {
                data: {
                    name: $('#node-modal-form-title').val(),
                    description: $('#node-modal-form-description').val(),
                    html_description: MarkdownIt.render($('#node-modal-form-description').val()),
                    color: $('#node-modal-form-colour').val(),
                    font_color: $('#node-modal-form-colour').css("color"),
                    parent: $('#node-modal-form-parent-id').val(),
                    associatedResources: Workflows.associatedResources.fetch(),
                    ontologyTerms: Workflows.ontologyTerms.fetch()
                },
                position: {
                    x: parseInt($("#node-modal-form-x", 10).val()),
                    y: parseInt($("#node-modal-form-y", 10).val())
                }
            };
        }
    },

    sidebar: {
        init: function () {
            var sidebar = $('#workflow-diagram-sidebar');
            sidebar.data('initialState', sidebar.html());
            //sidebar.html('');
        },

        populate: function (e) {
            if (e.cyTarget.isNode()) {
                // Hide all expanded nodes and edges not related to this one
                var relatives = e.cyTarget.ancestors().descendants();
                var unrelated = cy.$('.visible').difference(relatives);
                unrelated.removeClass('visible');
                unrelated.connectedEdges().addClass('hidden');

                // Show parents if they are hidden
                relatives.addClass('visible').connectedEdges().removeClass('hidden');

                // Show child nodes and their edges
                if (e.cyTarget.isParent()) {
                    e.cyTarget.children().addClass('visible').connectedEdges().removeClass('hidden');
                }

                if (!e.cyTarget.data('html_description') && e.cyTarget.data('description')) {
                    e.cyTarget.data('html_description', MarkdownIt.render(e.cyTarget.data('description')));
                }

                var resources = e.cyTarget.data('associatedResources');
                if (resources && resources.length > 0){
                    for(var i = 0; i < resources.length; i++) {
                        var resource = resources[i];
                        var uri = URI.parse(resource.url);
                        if (uri.hostname == 'bio.tools') {
                            var id = uri.path.split('/')[2];
                            Biotools.displayToolInfo(id);
                            resource.id =id
                        }
                    }
                }
                e.cyTarget.data('associatedResources', resources);

                $('#workflow-diagram-sidebar-title').html(e.cyTarget.data('name') || '<span class="muted">Untitled</span>')
                    .css('background-color', e.cyTarget.data('color'))
                    .css('color', e.cyTarget.data('font_color'));
                $('#workflow-diagram-sidebar-desc').html(HandlebarsTemplates['workflows/sidebar_content'](e.cyTarget.data()));

                Workflows.storeLastSelection();

                var zoom = 1.8;
                // Fit the view to the selected thing if it will be too big to fit in the viewport when zoomed
                if ((e.cyTarget.width() * zoom) > (cy.width() * 0.9)) {
                    cy.animate({ fit: { eles: e.cyTarget.children().union(e.cyTarget), padding: 40 }, duration: 300 })
                } else { // Or just zoom in on it
                    cy.animate({ center: { eles: e.cyTarget }, zoom: zoom, duration: 300 })
                }

            } else if (e.cyTarget.isEdge()) {
                var title = $('#workflow-diagram-sidebar-title');
                if (e.cyTarget.data('name')) {
                    title.html(e.cyTarget.data('name') + ' (edge)');
                } else {
                    title.html('<span class="muted">Untitled (edge)</span>');
                }

                title.css('background-color', '')
                     .css('color', '');
            }
        },

        clear: function () {
            var sidebar = $('#workflow-diagram-sidebar');
            sidebar.html(sidebar.data('initialState'));
        }
    },

    history: {
        initialize: function () {
            Workflows.history.index = 0;
            Workflows.history.stack = [{ action: 'initial state', elements: cy.elements().clone() }];
        },

        modify: function (action, modification) {
            if (typeof modification != 'undefined')
                modification();
            Workflows.history.stack.length = Workflows.history.index + 1; // Removes all "future" history after the current point.
            Workflows.history.index++;
            Workflows.history.stack.push({ action: action, elements: cy.elements().clone() });
            Workflows.history.setButtonState();
        },

        undo: function () {
            if (Workflows.history.index > 0) {
                Workflows.history.index--;
                Workflows.history.restore();
            }
        },

        redo: function () {
            if (Workflows.history.index < (Workflows.history.stack.length - 1)) {
                Workflows.history.index++;
                Workflows.history.restore();
            }
        },

        restore: function () {
            cy.elements().remove();
            Workflows.history.stack[Workflows.history.index].elements.restore();
            Workflows.history.setButtonState();
            Workflows.cancelState();
        },

        setButtonState: function () {
            if (Workflows.history.index < (Workflows.history.stack.length - 1)) {
                $('#workflow-toolbar-redo')
                    .removeClass('disabled')
                    .find('span')
                    .attr('title', 'Redo ' + Workflows.history.stack[Workflows.history.index + 1].action);
            } else {
                $('#workflow-toolbar-redo')
                    .addClass('disabled')
                    .find('span')
                    .attr('title', 'Redo');
            }

            if (Workflows.history.index > 0) {
                $('#workflow-save-warning').show();
                $('#workflow-toolbar-undo')
                    .removeClass('disabled')
                    .find('span')
                    .attr('title', 'Undo ' + Workflows.history.stack[Workflows.history.index].action);
            } else {
                $('#workflow-save-warning').hide();
                $('#workflow-toolbar-undo')
                    .addClass('disabled')
                    .find('span')
                    .attr('title', 'Undo');
            }
        }
    },

    associatedResources: {
        types: {
            materials: { icon: 'fa-book' },
            events: {icon: 'fa-calendar'},
            tools: { icon: 'fa-wrench' },
            policies: { icon: 'fa-file-text-o' }
        },

        // Add a new blank form for an associated resource
        add: function () {
            var type = $(this).data('resourceType');
            var template = HandlebarsTemplates['workflows/associated_resource_form'];

            $('#node-modal-associated-resource-list').append(template({
                type: type,
                icon: Workflows.associatedResources.types[type].icon
            }));

            return false;
        },

        delete: function () {
            $(this).parents('.associated-resource').remove();
            return false;
        },

        // Fetch the associated resources from the modal. Returns an array of objects that can be added to a node's data
        fetch: function (node) {
            var resources = [];
            $('#node-modal-associated-resource-list .associated-resource').each(function () {
                // "data-attribute" is just something I made up so I could identify the two form fields.
                // If I used the standard "name", they would end up getting posted to the server when the main workflow form is submitted.
                var resource = {
                    title: $('[data-attribute=title]', $(this)).val(),
                    url: $('[data-attribute=url]', $(this)).val(),
                    type: $('[data-attribute=type]', $(this)).val()
                };

                // Detect if URL is internal, and make it relative
                var base = window.location.toString().split('/workflows')[0];
                if (resource.url.indexOf(base) !== -1) {
                    resource.url = resource.url.substr(base.length)
                }

                if (resource.url && resource.title) {
                    resources.push(resource);
                }
            });

            return resources;
        },

        // Populate the modal with existing associated resource forms that can be edited by the user
        populate: function (resources) {
            var resourceList = $('#node-modal-associated-resource-list');
            resourceList.html('');

            for(var i = 0; i < resources.length; i++) {
                var resource = resources[i];
                resource.icon = Workflows.associatedResources.types[resource.type].icon;
                resourceList.append(
                    HandlebarsTemplates['workflows/associated_resource_form'](resource)
                );
            }
        }
    },

    ontologyTerms: {
        add: function (suggestion) {
            var template = HandlebarsTemplates['workflows/ontology_term_form'];

            $('#node-modal-ontology-terms-list').append(template({
                label: suggestion.data.preferred_label,
                uri: suggestion.data.uri
            }));

            return false;
        },

        delete: function () {
            $(this).parents('.ontology-term').remove();
            return false;
        },

        fetch: function (node) {
            return $('#node-modal-ontology-terms-list .ontology-term').map(function () {
                return { label: $(this).data('attributeLabel'),
                         uri: $(this).data('attributeUrl')
                };
            }).toArray();
        },

        populate: function (resources) {
            var resourceList = $('#node-modal-ontology-terms-list');
            resourceList.html('');

            for(var i = 0; i < resources.length; i++) {
                resourceList.append(
                    HandlebarsTemplates['workflows/ontology_term_form'](resources[i])
                );
            }
        }
    }
};

document.addEventListener("turbolinks:load", function() {
    var wfJsonElement = $('#workflow-content-json');
    var cytoscapeElement = $('#cy');
    var editable = cytoscapeElement.data('editable');
    var hideChildNodes = cytoscapeElement.data('hideChildNodes');

    if (wfJsonElement.length && cytoscapeElement.length) {
        var cy = window.cy = cytoscape({
            container: cytoscapeElement[0],
            elements: JSON.parse(wfJsonElement.html()),
            layout: {
                name: 'preset',
                padding: 20
            },
            style: [
                {
                    selector: 'node',
                    css: {
                        'shape': 'roundrectangle',
                        'content': 'data(name)',
                        'background-color': function (ele) {
                            return (typeof ele.data('color') === 'undefined') ? "#f47d20" : ele.data('color')
                        },
                        'color': function (ele) {
                            return (typeof ele.data('font_color') === 'undefined') ? "#000000" : ele.data('font_color')
                        },
                        'background-opacity': 0.8,
                        'text-valign': 'center',
                        'text-halign': 'center',
                        'width': '150px',
                        'height': '30px',
                        'font-size': '9px',
                        'border-width': '1px',
                        'border-color': '#000',
                        'border-opacity': 0.5,
                        'text-wrap': 'wrap',
                        'text-max-width': '130px'
                    }
                },
                {
                    selector: '$node > node',
                    css: {
                        'shape': 'roundrectangle',
                        'content': function (e) {
                            return e.data('name') + ' (' + e.children().length + ')';
                        },
                        'padding-top': '10px',
                        'font-weight': 'bold',
                        'padding-left': '10px',
                        'padding-bottom': '10px',
                        'padding-right': '10px',
                        'text-valign': 'top',
                        'text-halign': 'center',
                        'text-margin-y': '-2px',
                        'width': 'auto',
                        'height': 'auto',
                        'font-size': '9px',
                        'color': '#111111'
                    }
                },
                {
                    selector: 'edge',
                    css: {
                        'target-arrow-shape': 'triangle',
                        'content': 'data(name)',
                        'line-color': '#ccc',
                        'source-arrow-color': '#ccc',
                        'target-arrow-color': '#ccc',
                        'font-size': '9px',
                        'curve-style': 'bezier'
                    }
                },
                {
                    selector: ':selected',
                    css: {
                        'line-color': '#2A62E4',
                        'target-arrow-color': '#2A62E4',
                        'source-arrow-color': '#2A62E4',
                        'border-width': '2px',
                        'border-color': '#2A62E4',
                        'border-opacity': 1,
                        'background-blacken': '-0.1'
                    }
                }
            ],
            userZoomingEnabled: false,
            autolock: !editable
        });

        if (editable) {
            // Bind events
            $('#workflow-toolbar-add').click(Workflows.setAddNodeState);
            $('#workflow-toolbar-cancel').click(Workflows.cancelState);
            $('#workflow-toolbar-edit').click(Workflows.edit);
            $('#workflow-toolbar-link').click(Workflows.setLinkNodeState);
            $('#workflow-toolbar-undo').click(Workflows.history.undo);
            $('#workflow-toolbar-redo').click(Workflows.history.redo);
            $('#workflow-toolbar-add-child').click(Workflows.addChild);
            $('#workflow-toolbar-delete').click(Workflows.delete);
            $('#node-modal-form-confirm').click(Workflows.nodeModalConfirm);
            $('#edge-modal-form-confirm').click(Workflows.edgeModalConfirm);
            $('.node-modal-add-resource-btn').click(Workflows.associatedResources.add);
            $('#node-modal')
                .on('hide.bs.modal', Workflows.cancelState)
                .on('click', '.delete-associated-resource', Workflows.associatedResources.delete)
                .on('click', '.delete-ontology-term', Workflows.ontologyTerms.delete);

            $('#edge-modal').on('hide.bs.modal', Workflows.cancelState);

            $('.workflow-diagram-wrapper .modal').keydown(function (event) {
                if(event.target.tagName != 'TEXTAREA') {
                    if (event.keyCode == 13) {
                        event.preventDefault();
                        return false;
                    }
                }
            });

            // Update JSON in form
            $('.workflow-form-submit').click(function () {
                $('#workflow_workflow_content').val(JSON.stringify(cy.json()['elements']));
                Workflows.formSubmitted = true;

                return true;
            });

            cy.on('tap', Workflows.handleClick);
            cy.on('select', function (e) {
                if (Workflows.state !== 'adding node') {
                    Workflows.select(e.cyTarget);
                }
            });
            cy.on('unselect', Workflows.cancelState);
            cy.on('drag', function () {
                Workflows._dragged = true;
            });
            cy.on('free', function () {
                if (Workflows._dragged) {
                    Workflows.history.modify('move node');
                    Workflows._dragged = false;
                }
            });
            cy.$(':selected').unselect();
            cy.on('select', Workflows.sidebar.populate);

            // Initialize
            Workflows.cancelState();
            Workflows.history.initialize();
            jscolor.installByClassName('jscolor');
        } else {
            // Hiding/revealing of child nodes
            if(hideChildNodes) {
                cy.style()
                    .selector('node > node').style({ 'opacity': 0 })
                    .selector('node > node.visible').style({ 'opacity': 1, 'transition-property': 'opacity', 'transition-duration': '0.2s' })
                    .selector('edge.hidden').style({ 'opacity': 0 })
                    .update();

                cy.$('node > node').connectedEdges().addClass('hidden');
            }
            cy.on('select', 'node', Workflows.sidebar.populate);
            cy.on('select', 'edge', function (e) {
                e.cyTarget.unselect();
                return false;
            });
        }

        Workflows.sidebar.init();
        cy.on('unselect', Workflows.sidebar.clear);
        cy.$(':selected').unselect();
        Workflows.loadLastSelection();

        cy.panzoom();
        var defaultZoom = cy.maxZoom();
        cy.maxZoom(2); // Temporary limit the zoom level, to restrict how zoomed-in the diagram appears by default
        cy.fit(50); // Fit diagram to screen with some padding around the edges
        cy.maxZoom(defaultZoom); // Reset the zoom limit to allow user to further zoom if they wish

        Split(['#workflow-diagram-content', '#workflow-diagram-sidebar'], {
            direction: 'horizontal',
            sizes: [70, 30],
            minSize: [100, 50],
            onDragEnd: function() {
                cy.resize();
            }
        });
    }
});
