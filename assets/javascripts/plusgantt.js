/* Redmine - project management software
   Copyright (C) 2006-2016  Jean-Philippe Lang */

var draw_gantt = null;
var draw_top;
var draw_right;
var draw_left;

var rels_stroke_width = 2;

function markupSubject(htmlId) {
	$("#" + htmlId).addClass('markupSubject');
}

function unMarkupSubject(htmlId) {
	$("#" + htmlId).removeClass('markupSubject');
}

function markupTask(htmlId) {
	$("#" + htmlId).addClass('markupTask');
}

function unMarkupTask(htmlId) {
	$("#" + htmlId).removeClass('markupTask');
}

function toggleIssue(task, style, action) {
	draw_gantt.clear();
	($("#draw_relations").prop('checked', false))
	if (action == 'hide') {
		hide = true;
		$("#" + task).val('+');
		$("#" + task).removeClass('icon-open-tree');
		$("#" + task).addClass('icon-close-tree');
	} else {
		if (action == 'show') {
			hide = false;
			$("#" + task).val('-')
			$("#" + task).removeClass('icon-close-tree');
			$("#" + task).addClass('icon-open-tree');
		} else {
			if ($("#" + task).val() == '-' || $("#" + task).val() == '' || $("#" + task).val() == undefined) {
				hide = true;
				$("#" + task).val('+');
				$("#" + task).removeClass('icon-open-tree');
				$("#" + task).addClass('icon-close-tree');
				action = 'hide';
			} else {
				hide = false;
				$("#" + task).val('-');
				$("#" + task).removeClass('icon-close-tree');
				$("#" + task).addClass('icon-open-tree');
				action = 'show';
			}
		}
	};
	
	$.each($("div." + style + ", div.subject-issue-" + style + ", div.task-issue-" + style), function(index, element) {
		var element_id = $(element).attr("id");
		if (element_id != null) {
			if (hide) {
				$("#" + element_id).fadeOut();
			} else {
				$("#" + element_id).fadeIn();
			}
			toggleIssue("span-" + element_id, element_id, action);
		};
	});
	
	if (action == '' || action == null) {
		if ($("#draw_relations").prop('checked')) {
			drawRelations();
		}
	}
}

function setDrawArea() {
  draw_top   = $("#gantt_draw_area").position().top;
  draw_right = $("#gantt_draw_area").width();
  draw_left  = $("#gantt_area").scrollLeft();
}

function getRelationsArray() {
  var arr = new Array();
  $.each($('div.pgtask_todo[data-rels], div.pgtask_late[data-rels], div.pgtask_done[data-rels]'), function(index_div, element) {
    var element_id = $(element).attr("id");
    if (element_id != null) {
      var issue_id = element_id.replace("task-line-issue-", "");
      var data_rels = $(element).data("rels");
      for (rel_type_key in data_rels) {
        $.each(data_rels[rel_type_key], function(index_issue, element_issue) {
          arr.push({issue_from: issue_id, issue_to: element_issue,
                    rel_type: rel_type_key});
        });
      }
    }
  });
  return arr;
}

function drawRelations() {
  var arr = getRelationsArray();
  $.each(arr, function(index_issue, element_issue) {
    var issue_from = $("#task-issue-" + element_issue["issue_from"]);
    var issue_to   = $("#task-issue-" + element_issue["issue_to"]);
    if (issue_from.size() == 0 || issue_to.size() == 0) {
		return;
    }
    var issue_height = issue_from.height();
    var issue_from_top   = issue_from.position().top  + (issue_height / 2) + 6;
    var issue_from_right = issue_from.position().left - 15 + issue_from.width();
    var issue_to_top   = issue_to.position().top  + (issue_height / 2) + 6;
    var issue_to_left  = issue_to.position().left;
    var color = issue_relation_type[element_issue["rel_type"]]["color"];
    var landscape_margin = issue_relation_type[element_issue["rel_type"]]["landscape_margin"];
    var issue_from_right_rel = issue_from_right + landscape_margin;
    var issue_to_left_rel    = issue_to_left    - landscape_margin;
    draw_gantt.path(["M", issue_from_right,     issue_from_top,
                     "L", issue_from_right_rel, issue_from_top])
                   .attr({stroke: color,
                          "stroke-width": rels_stroke_width
                          });
    if (issue_from_right_rel < issue_to_left_rel) {
      draw_gantt.path(["M", issue_from_right_rel + draw_left, issue_from_top,
                       "L", issue_from_right_rel + draw_left, issue_to_top])
                     .attr({stroke: color,
                          "stroke-width": rels_stroke_width
                          });
      draw_gantt.path(["M", issue_from_right_rel + draw_left, issue_to_top,
                       "L", issue_to_left + draw_left,        issue_to_top])
                     .attr({stroke: color,
                          "stroke-width": rels_stroke_width
                          });
    } else {
      var issue_middle_top = issue_to_top +
                                (issue_height *
                                   ((issue_from_top > issue_to_top) ? 1 : -1));
      draw_gantt.path(["M", issue_from_right_rel + draw_left, issue_from_top,
                       "L", issue_from_right_rel + draw_left, issue_middle_top])
                     .attr({stroke: color,
                          "stroke-width": rels_stroke_width
                          });
      draw_gantt.path(["M", issue_from_right_rel + draw_left, issue_middle_top,
                       "L", issue_to_left_rel + draw_left,    issue_middle_top])
                     .attr({stroke: color,
                          "stroke-width": rels_stroke_width
                          });
      draw_gantt.path(["M", issue_to_left_rel + draw_left, issue_middle_top,
                       "L", issue_to_left_rel + draw_left, issue_to_top])
                     .attr({stroke: color,
                          "stroke-width": rels_stroke_width
                          });
      draw_gantt.path(["M", issue_to_left_rel + draw_left, issue_to_top,
                       "L", issue_to_left + draw_left,     issue_to_top])
                     .attr({stroke: color,
                          "stroke-width": rels_stroke_width
                          });
    }
    draw_gantt.path(["M", issue_to_left + draw_left, issue_to_top,
                     "l", -4 * rels_stroke_width, -2 * rels_stroke_width,
                     "l", 0, 4 * rels_stroke_width, "z"])
                   .attr({stroke: "none",
                          fill: color,
                          "stroke-linecap": "butt",
                          "stroke-linejoin": "miter"
                          });
  });
}

function drawGanttHandler() {
	var folder = document.getElementById('gantt_draw_area');
	if(draw_gantt != null)
		draw_gantt.clear();
	else
		draw_gantt = Raphael(folder);
	
	setDrawArea();
	
	if ($("#draw_relations").prop('checked')) {
		drawRelations();
	}
}
