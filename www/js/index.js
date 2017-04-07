var token = window.location.search.substring(1);

function show_module_info(name) {
    $.ajax({
      url: "/api/modules/" + name,
      data: JSON.stringify({pass: token}),
      contentType: "application/json",
      dataType: "json",
      method: "POST",
      cache: false
    }).done(function (res) {
      if (res.status === 'OK') {
        $('#module_list > a.module').removeClass('active');
        $('#module_list > a[module=' + name + ']').addClass('active');
        $('#main_display').empty();
        $('#main_display').append('<h2 class="inline">' + toTitleCase(res.data.display_name) + '</h2>' + (res.data.author ? '<h5 class="inline"> by ' + res.data.author + '</h5>': ''));
        $('#main_display').append('<div id="module_info" class="well"></div>');
        if (res.data.usage || res.data.usage === '')
          $('#module_info').append(
            '<div class="row"><div class="col-md-12">' +
            '<p>Usage: <pre>' + res.data.prefix + res.data.name + ' ' + htmlEscape(res.data.usage) + '</pre></p>' + 
            '</div></div>');
        if (res.data.description)
          $('#module_info').append(
            '<div class="row"><div class="col-md-12">' +
            '<p>Description: <pre>' + htmlEscape(res.data.description) + '</pre></p>' + 
            '</div></div>');
        if (Object.keys(res.data.options).length > 0) {
          $('#main_display').append(
            '<div module="' + name + '" id="module_options" class="well"></div>');
          $('#module_options').append(
            '<div class="row">' +
              '<div class="col-md-12">' +
                '<span class="pull-right">' +
                  '<a id="apply_options" class="btn btn-success">Apply changes</a>' +
                '</span>' +
                '<h5 class="inline">Configuration</h5>' +
              '</div>' +
            '</div>');
          $('#module_options').append('<hr/>');
          
          $('#apply_options').on('click', function() {
            var m = $('#module_options').attr('module');
            var options = {}
            var childs = $('#module_options > div > div > .option-value');
            for (var i = 0; i < childs.length; i++) {
              var type = $(childs[i]).attr('type');
              var name = $(childs[i]).attr('option');
              switch(type) {
                case ('toggle'):
                  options[name] = $(childs[i]).children('label').children('input').prop('checked');
                break;
              }
            }
            $.ajax({
              url: "/api/modules/" + m,
              data: JSON.stringify({pass: token, options: options}),
              contentType: "application/json",
              dataType: "json",
              method: "POST",
              cache: false
            });
          });
          
          for (var i in res.data.options) {
            var o = res.data.options[i]; // Current option
            var v = res.data.options_values[i]; // Current option value
            var option_html = '';
            
            switch(o.type) {
              case "toggle":
                option_html = 
                  '<label class="toggle">' +
                    '<input type="checkbox"' + (v ? ' checked' : '') + '/>' +
                    '<span class="handle"></span>' +
                  '</label>'
                break;
            }
            
            $('#module_options').append(
              '<div class="row">' +
                '<div class="col-md-12">' +
                  '<span  type="' + o.type + '" option="' + i + '" class="option-value pull-right">' +
                    option_html +
                  '</span>' +
                  '<p>' + o.label + '</p>' +
                '</div>' +
              '</div>');
          }
        }
      }
    });
}

function refresh_module_list() {
    $.ajax({
	url: "/api/modules",
	data: JSON.stringify({pass: token}),
	contentType: "application/json",
	dataType: "json",
	method: "POST",
	cache: false
    }).done(function (res) {
      if (res.status === 'OK') {
	$('#module_list > a.module').remove()
	for (var i in res.data) {
	    var m = res.data[i]; // Current module
	    var checked = m.enabled ? ' checked' : '';
	    $('#module_list').append(
              '<a class="module list-group-item" module="' + m.name + '">' +
                toTitleCase(m.display_name) + ' (' + m.name + ')' +
                '<span style="margin-top: -6px;" class="pull-right">' +
                  '<label class="toggle">' +
                    '<input type="checkbox"' + checked + '/>' +
                    '<span class="handle"></span>' +
                  '</label>' +
                '</span>' +
              '</a>');
	}
	$('#module_list > a.module').on('click', function() {
	    show_module_info($(this).attr('module'));
	});
	$('#module_list > a.module > span > label > input').on('click', function() {
	    var name = $(this).parent().parent().parent().attr('module');
	    $.ajax({
		url: "/api/modules/" + name,
		data: JSON.stringify({pass: token, enabled: $(this).prop('checked')}),
		contentType: "application/json",
		dataType: "json",
		method: "POST",
		cache: false
	    });
	});
      }
    });
}

$(function() {
    $('#refresh_list').on('click', refresh_module_list);


    refresh_module_list();
})

function htmlEscape(str) {
    return str
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

// I needed the opposite function today, so adding here too:
function htmlUnescape(str){
    return str
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&');
}

function toTitleCase(str)
{
    return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
}
