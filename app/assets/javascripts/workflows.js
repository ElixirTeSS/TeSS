$(document).ready(function () {
    var wfJsonElement = $('#workflow-content-json');
    var cytoscapeElement = $('#cy');

    if(wfJsonElement.length) {
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
                        'content': 'data(short_name)',
                        'background-color': 'data(color)',
                        'text-valign': 'center',
                        'text-halign': 'center',
                        'width': '150px',
                        'height': '30px',
                        'font-size': '9px',
                        'border-width': '1px',
                        'border-color': '#999'
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
                        'content': 'data(short_name)',
                        'line-color': '#ccc',
                        'source-arrow-color': '#ccc',
                        'target-arrow-color': '#ccc',
                        'font-size': '9px'
                    }
                },
                {
                    selector: ':selected',
                    css: {
                        'background-color': 'data(color)',
                        'line-color': '#2A62E4',
                        'target-arrow-color': '#2A62E4',
                        'source-arrow-color': '#2A62E4',
                        'border-width': '2px',
                        'border-color': '#2A62E4',
                        'background-blacken': '0.3'
                    }
                }
            ],
            userZoomingEnabled: false,
            autolock: !cytoscapeElement.data('editable')
        });

        cy.panzoom();
    }

    $('#workflow-toolbar-add').click(Workflows.setAddNodeState);
    $('#workflow-toolbar-cancel').click(Workflows.cancelState);
    $('#workflow-modal-form-confirm').click(Workflows.addNode);
    cy.on('tap', Workflows.placeNode);

    $('#workflow-modal').on('hide.bs.modal', Workflows.cancelState);

    // Update JSON in form
    $('#workflow-form-submit').click(function () {
        $('#workflow_workflow_content').val(JSON.stringify(cy.json()['elements']));

        return true;
    });
});

Workflows = {};

Workflows.setAddNodeState = function () {
    Workflows.setState('adding node', 'Click on the diagram to add a new node.');
};

Workflows.placeNode = function (e) {
    if(Workflows.state === 'adding node') {
        Workflows.cancelState();
        $('#workflow-modal').modal('show');
        $('#workflow-modal-form-title').val('');
        $('#workflow-modal-form-description').val('');
        //$('#workflow-modal-form-colour').val('#88CC33');
        //$('#workflow-modal-form-colour').css('background-color', '#88CC33');
        //$('#workflow-modal-form-colour').css('color', '#000000');
        $('#workflow-modal-form-x').val(e.cyPosition.x);
        $('#workflow-modal-form-y').val(e.cyPosition.y);
    }
};

Workflows.addNode = function () {
    var object = {
        group: 'nodes',
        data: {
            name: $('#workflow-modal-form-title').val(),
            short_name: $('#workflow-modal-form-title').val(),
            content: $('#workflow-modal-form-title').val(),
            color: $('#workflow-modal-form-colour').val()
        },
        position: {
            x: parseInt($('#workflow-modal-form-x').val()),
            y: parseInt($('#workflow-modal-form-y').val())
        },
        selected: true
    };

    cy.add(object);
    $('#workflow-modal').modal('hide');
};

Workflows.cancelState = function () {
    Workflows.state = '';
    $('#workflow-status-bar span').html('');
    $('#workflow-toolbar-cancel').hide();   
};

Workflows.setState = function (state, message) {
    Workflows.state = state;
    $('#workflow-status-bar span').html(message);
    var button = $('#workflow-toolbar-cancel');
    button.find('span').html('Cancel ' + state);
    button.show();
};
