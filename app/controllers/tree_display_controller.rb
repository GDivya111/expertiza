class TreeDisplayController < ApplicationController
  helper :application

  def action_allowed?
    true
  end

#refactored method to provide direct access to parameters
  def goto_controller(name_parameter)
    node_object = TreeFolder.find_by(name: name_parameter)
    session[:root] = FolderNode.find_by(node_object_id: node_object.id).id
    redirect_to controller: 'tree_display', action: 'list'
  end

  def confirm
    @id = params[:id]
    @node_type = params[:nodeType]
  end

  # direct access to questionnaires
  def goto_questionnaires
    goto_controller('Questionnaires')
  end

  # direct access to review rubrics
  def goto_review_rubrics
    goto_controller('Review')
  end

  # direct access to metareview rubrics
  def goto_metareview_rubrics
    goto_controller('Metareview')
  end

  # direct access to teammate review rubrics
  def goto_teammatereview_rubrics
    goto_controller('Teammate Review')
  end

  # direct access to author feedbacks
  def goto_author_feedbacks
    goto_controller('Author Feedback')
  end

  # direct access to global survey
  def goto_global_survey
    goto_controller('Global Survey')
  end

  # direct access to surveys
  def goto_surveys
    goto_controller('Survey')
  end

  # direct access to course evaluations
  def goto_course_evaluations
    goto_controller('Course Evaluation')
  end

  # direct access to courses
  def goto_courses
    goto_controller('Courses')
  end

  def goto_bookmarkrating_rubrics
    goto_controller('Bookmarkrating')
  end

  # direct access to assignments
  def goto_assignments
    goto_controller('Assignments')
  end

  # called when the display is requested
  # ajbudlon, July 3rd 2008
  def list
    redirect_to controller: :content_pages, action: :view if current_user.nil?
    redirect_to controller: :student_task, action: :list if current_user.try(:student?)
  end

  def confirm_notifications_access
    redirect_to controller: :notifications, action: :list if current_user.try(:student?)
  end

  #renders FolderNode json
  def folder_node_ng_getter
    respond_to do |format|
      format.html { render json: FolderNode.get }
    end
  end

def get_courses_node_ng
    respond_to do |format|

    courses = []

    if session[:user].role.name == 'Teaching Assistant'
      ta = Ta.find(session[:user].id)
      ta.ta_mappings.each {|mapping| courses << Course.find(mapping.course_id) }
      # If a TA created some courses before, s/he can still add new assignments to these courses.
      courses << Course.where(instructor_id: session[:user].id)
      courses.flatten!
    # Administrator and Super-Administrator can see all courses
    elsif session[:user].role.name == 'Administrator' or session[:user].role.name == 'Super-Administrator'
      courses = Course.all
    elsif session[:user].role.name == 'Instructor'
      courses = Course.where(instructor_id: session[:user].id)
      # instructor can see courses his/her TAs created
      ta_ids = []
      ta_ids << Instructor.get_my_tas(session[:user].id)
      ta_ids.flatten!
      ta_ids.each do |ta_id|
        ta = Ta.find(ta_id)
        ta.ta_mappings.each {|mapping| courses << Course.find(mapping.course_id) }
      end
    end
      format.html { render json:courses}

    end
  end

  #finding out child_nodes from params
  def child_nodes_from_params(child_nodes)
    if child_nodes.is_a? String
      JSON.parse(child_nodes)
    else
      child_nodes
    end
  end

  #getting all attributes of assignment node
  def assignments_method(node, tmp_object)
    tmp_object.merge!(
      "course_id" => node.get_course_id,
      "max_team_size" => node.get_max_team_size,
      "is_intelligent" => node.get_is_intelligent,
      "require_quiz" => node.get_require_quiz,
      "quiz_questions" => node.get_quiz_questions,
      "allow_suggestions" => node.get_allow_suggestions,
      "spec_location" => node.get_spec_location,
      "staggered_deadline" =>node.get_staggered_deadline,
      "microtask" => node.get_microtask,
      "review_visible" => node.get_review_visible,
      "calibration" => node.get_calibration,
      "reputation" => node.get_reputation_algorithm,
      "teammate_review" => node.get_teammate_review,
      "availability" => node.get_availability,
      "has_topic" => SignUpTopic.where(['assignment_id = ?', node.node_object_id]).first ? true : false
    )
  end

  def update_in_ta_course_listing(instructor_id, node, tmp_object)
    tmp_object["private"] = true if session[:user].role.ta? == 'Teaching Assistant' &&
        Ta.get_my_instructors(session[:user].id).include?(instructor_id) &&
        ta_for_current_course?(node)
  end

  def update_is_available(tmp_object, instructor_id, node)
    tmp_object["is_available"] = is_available(session[:user], instructor_id) || (session[:user].role.ta? &&
        Ta.get_my_instructors(session[:user].id).include?(instructor_id) && ta_for_current_course?(node))
  end

#updating instructor value for tmp_object
  def update_instructor(tmp_object, instructor_id)
    tmp_object["instructor_id"] = instructor_id
    tmp_object["instructor"] = nil
    tmp_object["instructor"] = User.find(instructor_id).name if instructor_id
  end

  def update_tmp_obj(tmp_object, node)
    tmp={
      "directory" => node.get_directory,
      "creation_date" => node.get_creation_date,
      "updated_date" => node.get_modified_date,
      "institution" => Institution.where(id: node.retrieve_institution_id),
      "private" => node.get_instructor_id == session[:user].id ? true : false
       }
   tmp_object.merge!(tmp)
  end

  def courses_assignments_obj(node_type, tmp_object, node)
    update_tmp_obj(tmp_object, node)
    # tmpObject["private"] = node.get_private
    instructor_id = node.get_instructor_id
    ## if current user's role is TA for a course, then that course will be listed under his course listing.
    update_in_ta_course_listing(instructor_id, node, tmp_object)
    update_instructor(tmp_object, instructor_id)
    update_is_available(tmp_object, instructor_id, node)
    assignments_method(node, tmp_object) if node_type == "Assignments"
  end

#getting result nodes for child
  def res_node_for_child(tmp_res)
    res = {}
    tmp_res.keys.each do |node_type|
      res[node_type] = []
      tmp_res[node_type].each do |node|
        tmp_object = {
          "nodeinfo" => node,
          "name" => node.get_name,
          "type" => node.type
        }
        if node_type == 'Courses' || node_type == "Assignments"
          courses_assignments_obj(node_type, tmp_object, node)
        end
        res[node_type] << tmp_object
      end
    end
    res
  end

  def update_fnode_children(fnode, tmp_res)
    # fnode is short for foldernode which is the parent node
    # ch_nodes are childrens
    # cnode = fnode.get_children("created_at", "desc", 2, nil, nil)
    ch_nodes = fnode.get_children(nil, nil, session[:user].id, nil, nil)
    tmp_res[fnode.get_name] = ch_nodes
  end

#initialize parent node and update child nodes for it
  def initialize_fnode_update_children(params, node, tmp_res)
    fnode = (params[:reactParams][:nodeType]).constantize.new
    node.each do |a|
      fnode[a[0]] = a[1]
    end
    update_fnode_children(fnode, tmp_res)
  end

  # for child nodes
  def children_node_ng
    child_nodes = child_nodes_from_params(params[:reactParams][:child_nodes])
    tmp_res = {}
    child_nodes.each do |node|
      initialize_fnode_update_children(params, node, tmp_res)
    end
    res = res_node_for_child(tmp_res)
    respond_to do |format|
      format.html { render json: res }
    end
  end

  #check if nodetype is coursenode
  def is_type_coursenode?(ta_mappings, node)
    ta_mappings.each do |ta_mapping|
      return true if ta_mapping.course_id == node.node_object_id
    end
  end

  #check if nodetype is assignmentnode
  def is_type_assignmentnode?(ta_mappings, node)
    course_id = Assignment.find(node.node_object_id).course_id
    ta_mappings.each do |ta_mapping|
      return true if ta_mapping.course_id == course_id
    end
  end

  #check if user is ta for current course
  def ta_for_current_course?(node)
    ta_mappings = TaMapping.where(ta_id: session[:user].id)
    if node.type == "CourseNode"
      return true if is_type_coursenode?(ta_mappings, node)
    elsif node.type == "AssignmentNode"
      return true if is_type_assignmentnode?(ta_mappings, node)
    end
    false
  end

#check if current user is ta for instructor
  def is_user_ta?(instructor_id, child)
    # instructor created the course, current user is the ta of this course.
    session[:user].role_id == 6 and
        Ta.get_my_instructors(session[:user].id).include?(instructor_id) and ta_for_current_course?(child)
  end

#check if current user is instructor
  def is_user_instructor?(instructor_id)
    # ta created the course, current user is the instructor of this ta.
    instructor_ids = []
    TaMapping.where(ta_id: instructor_id).each {|mapping| instructor_ids << Course.find(mapping.course_id).instructor_id }
    session[:user].role_id == 2 and instructor_ids.include? session[:user].id
  end

  def update_is_available_2(res2, instructor_id, child)
    # current user is the instructor (role can be admin/instructor/ta) of this course. is_available_condition1
    res2["is_available"] = is_available(session[:user], instructor_id) ||
        is_user_ta?(instructor_id, child) ||
        is_user_instructor?(instructor_id)
  end

  #attaches assignment nodes to course node of instructor
  def coursenode_assignmentnode(res2, child)
    res2["directory"] = child.get_directory
    instructor_id = child.get_instructor_id
    update_instructor(res2, instructor_id)
    update_is_available_2(res2, instructor_id, child)
    assignments_method(child, res2) if child.type == "AssignmentNode"
  end

  #getting result nodes for child2. res[] contains all the resultant nodes.
  def res_node_for_child_2(ch_nodes)
    res = []

    if ch_nodes
      ch_nodes.each do |child|
        node_type = child.type
        res2 = {
          "nodeinfo" => child,
          "name" => child.get_name,
          "key" => params[:reactParams2][:key],
          "type" => node_type,
          "private" => child.get_private,
          "creation_date" => child.get_creation_date,
          "updated_date" => child.get_modified_date
        }
        if node_type == 'CourseNode' || node_type == "AssignmentNode"
          coursenode_assignmentnode(res2, child)
        end
        res << res2
      end
    end
   res
  end

  #initialising folder node 2
  def initialize_fnode_2(fnode, child_nodes)
    child_nodes.each do |key, value|
      fnode[key] = value
    end
  end


  def get_tmp_res(params, child_nodes)
    fnode = (params[:reactParams2][:nodeType]).constantize.new
    initialize_fnode_2(fnode, child_nodes)
    ch_nodes = fnode.get_children(nil, nil, session[:user].id, nil, nil)
    res_node_for_child_2(ch_nodes)
  end

  # for child nodes
  def children_node_2_ng
    child_nodes = child_nodes_from_params(params[:reactParams2][:child_nodes])
    res = get_tmp_res(params, child_nodes)
    respond_to do |format|
      format.html { render json: res }
    end
  end

  def bridge_to_is_available
    user = session[:user]
    owner_id = params[:owner_id]
    is_available(user, owner_id)
  end

  #gets and renders last open tab from session
  def session_last_open_tab
    res = session[:last_open_tab]
    respond_to do |format|
      format.html { render json: res }
    end
  end

#sets the last open tab from params
  def set_session_last_open_tab
    session[:last_open_tab] = params[:tab]
    res = session[:last_open_tab]
    respond_to do |format|
      format.html { render json: res }
    end
  end

  def drill
    session[:root] = params[:root]
    redirect_to controller: 'tree_display', action: 'list'
  end

#if filter node is 'QAN', get the corresponding assignment questionnaires
 def filter_node_is_qan(search, qid)
    assignment = Assignment.find_by(name: search)
    if assignment
      assignment_questionnaires = AssignmentQuestionnaire.where(assignment_id: assignment.id)
      if assignment_questionnaires
        assignment_questionnaires.each {|q| qid << "#{q.questionnaire_id}+" }
        session[:root] = 1
      end
    end
    qid
  end

  def filter
    qid = 'filter+'
    search = params[:filter_string]
    filter_node = params[:filternode]
    if filter_node == 'QAN'
      qid = filter_node_is_qan(search, qid)
    elsif filter_node == 'ACN'
      session[:root] = 2
      qid << search
    end
    qid
  end
end
