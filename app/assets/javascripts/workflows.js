$(document).ready(function () {
    var wfJsonElement = $('#workflow-content-json');
    var cytoscapeElement = $('#cy');
    var editable = cytoscapeElement.data('editable');

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
                        'background-color': 'data(color)',
                        'background-opacity': 0.8,
                        'text-valign': 'center',
                        'text-halign': 'center',
                        'width': '150px',
                        'height': '30px',
                        'font-size': '9px',
                        'border-width': '1px',
                        'border-color': '#000',
                        'border-opacity': 0.5
                    }
                },
                {
                    selector: '$node > node',
                    css: {
                        'shape': 'roundrectangle',
                        'padding-top': '10px',
                        'font-weight': 'bold',
                        'padding-left': '10px',
                        'padding-bottom': '10px',
                        'padding-right': '10px',
                        'text-valign': 'top',
                        'text-halign': 'center',
                        'width': 'auto',
                        'height': 'auto',
                        'font-size': '9px'
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

        cy.panzoom();
    }

    if (editable) {
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
        cy.on('tap', Workflows.handleClick);
        cy.on('select', function (e) {
            if (Workflows.state !== 'adding node') {
                Workflows.select(e.cyTarget);
            }
        });
        cy.on('unselect', Workflows.cancelState);
        cy.on('drag', function () { Workflows._dragged = true; });
        cy.on('free', function () {
            if (Workflows._dragged) {
                Workflows.history.modify('move node');
                Workflows._dragged = false;
            }
        });

        $('#node-modal').on('hide.bs.modal', Workflows.cancelState);
        $('#edge-modal').on('hide.bs.modal', Workflows.cancelState);

        // Update JSON in form
        $('#workflow-form-submit').click(function () {
            $('#workflow_workflow_content').val(JSON.stringify(cy.json()['elements']));

            return true;
        });

        cy.$(':selected').unselect();
        Workflows.cancelState();
        Workflows.history.initialize();
        jscolor.installByClassName('jscolor');
    } else {
        Workflows.sidebar.init();
        cy.on('select', Workflows.sidebar.populate);
        cy.on('unselect', Workflows.sidebar.clear);
        cy.$(':selected').unselect();
    }
});

Workflows = {
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
        $('#workflow-status-message').html(message);
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

        $('#workflow-status-message').html('');
        $('#workflow-status-selected-node').html('<span class="muted">nothing</span>');
        $('#workflow-status-bar').find('.node-context-button').hide();
        $('#workflow-toolbar-cancel').hide();
    },

    select: function (target) {
        if (target.isNode()) {
            Workflows.selected = target;
            Workflows.setState('node selection');
            $('#workflow-status-bar').find('.node-context-button').show();
            $('#workflow-status-selected-node').html(Workflows.selected.data('name'));
        } else if (target.isEdge()) {
            Workflows.selected = target;
            Workflows.setState('edge selection');
            $('#workflow-status-bar').find('.edge-context-button').show();
            $('#workflow-status-selected-node').html(Workflows.selected.data('name') + ' (edge)');
        }
    },

    setAddNodeState: function () {
        Workflows.cancelState();
        Workflows.setState('adding node', 'Click on the diagram to add a new node.');
    },

    placeNode: function (position, parentId) {
        $('#node-modal-title').html(parentId ? 'Add child node' : 'Add node');
        $('#node-modal').modal('show');
        $('#node-modal-form-id').val('');
        $('#node-modal-form-title').val('');
        $('#node-modal-form-description').val('');
        $('#node-modal-form-colour').val('#F0721E')[0].jscolor.fromString('#F0721E');
        $('#node-modal-form-parent-id').val(parentId);
        $('#node-modal-form-x').val(position.x);
        // Offset child nodes a bit so they don't stack on top of each other...
        var y = position.y;
        if (parentId && Workflows.selected.children().length > 0)
            y = Workflows.selected.children().last().position().y + 40;
        $('#node-modal-form-y').val(y);
    },

    addNode: function () {
        var object = {
            group: 'nodes',
            data: {
                name: $('#node-modal-form-title').val(),
                description: $('#node-modal-form-description').val(),
                color: $('#node-modal-form-colour').val(),
                parent: $('#node-modal-form-parent-id').val()
            },
            position: {
                x: parseInt($('#node-modal-form-x').val()),
                y: parseInt($('#node-modal-form-y').val())
            }
        };

        $('#node-modal').modal('hide');

        Workflows.history.modify(object.data.parent ? 'add child node' : 'add node', function () {
            cy.add(object).select();
        });
    },

    addChild: function () {
        Workflows.placeNode(Workflows.selected.position(), Workflows.selected.id());
    },

    edit: function () {
        if (Workflows.state === 'node selection') {
            var data = Workflows.selected.data();
            var position = Workflows.selected.position();
            $('#node-modal-title').html('Edit node');
            $('#node-modal').modal('show');
            $('#node-modal-form-id').val(data.id);
            $('#node-modal-form-title').val(data.name);
            $('#node-modal-form-description').val(data.description);
            $('#node-modal-form-colour').val(data.color)[0].jscolor.fromString(data.color);
            $('#node-modal-form-parent-id').val(data.parent);
            $('#node-modal-form-x').val(position.x);
            $('#node-modal-form-y').val(position.y);
        } else if (Workflows.state === 'edge selection') {
            var data = Workflows.selected.data();
            $('#edge-modal').modal('show');
            $('#edge-modal-form-label').val(data.name);
        }
    },

    updateNode: function () {
        var node = Workflows.selected;
        Workflows.history.modify('edit node', function () {
            node.data('name', $('#node-modal-form-title').val());
            node.data('description', $('#node-modal-form-description').val());
            node.data('color', $('#node-modal-form-colour').val());
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
        if ($('#node-modal-form-id').val()) {
            Workflows.updateNode();
        } else {
            Workflows.addNode();
        }
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
            Workflows.history.modify('delete node', function () {
                Workflows.selected.remove();
            });
            Workflows.cancelState();
        }
    },

    sidebar: {
        init: function () {
            var sidebar = $('#workflow-diagram-sidebar');
            sidebar.data('initialState', sidebar.html());
            sidebar.html('');
        },

        populate: function (e) {
            if (e.cyTarget.isNode()) {
                $('#workflow-diagram-sidebar-title').html(e.cyTarget.data('name') || '<span class="muted">Untitled</span>');
                $('#workflow-diagram-sidebar-desc').html(e.cyTarget.data('description') || '<span class="muted">No description provided</span>');
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
                $('#workflow-toolbar-undo')
                    .removeClass('disabled')
                    .find('span')
                    .attr('title', 'Undo ' + Workflows.history.stack[Workflows.history.index].action);
            } else {
                $('#workflow-toolbar-undo')
                    .addClass('disabled')
                    .find('span')
                    .attr('title', 'Undo');
            }
        }
    }
};
