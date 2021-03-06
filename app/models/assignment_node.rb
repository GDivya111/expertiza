# Node type for Assignments

# Author: ajbudlon
# Date: 7/18/2008

class AssignmentNode < Node
  belongs_to :assignment, class_name: "Assignment", foreign_key: "node_object_id"
  belongs_to :node_object, class_name: 'Assignment'
  # Returns the table in which to locate Assignments
  def self.table
    "assignments"
  end

  # parametersi:
  #   sortvar: valid strings - name, created_at, updated_at, directory_path
  #   sortorder: valid strings - asc, desc
  #   user_id: instructor id for assignment
  #   parent_id: course_id if subset

  # returns: list of AssignmentNodes based on query
  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, search = nil)
    if show
      conditions = if User.find(user_id).role.name != "Teaching Assistant"
                     'assignments.instructor_id = ?'
                   else
                     'assignments.course_id in (?)'
                   end
    else
      if User.find(user_id).role.name != "Teaching Assistant"
        conditions = '(assignments.private = 0 or assignments.instructor_id = ?)'
        values = user_id
      else
        conditions = '(assignments.private = 0 or assignments.course_id in (?))'
        values = Ta.get_mapped_courses(user_id)
      end
    end

    conditions += " and course_id = #{parent_id}" if parent_id
    sortvar ||= 'created_at'
    sortorder ||= 'desc'

    if search
      conditions += " and assignments.name LIKE ?"
      search = "%#{search}%"
      find_conditions = [conditions, values, search]
    else
      find_conditions = [conditions, values]
    end
    self.includes(:assignment).where(find_conditions).order("assignments.#{sortvar} #{sortorder}")
  end

  # Indicates that this object is always a leaf
  def is_leaf
    true
  end

  # Gets the name from the associated object
  # Gets the name from the associated object
  def get_name
    # Assignment.find(self.node_object_id).name
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.name
  end

  # Gets the directory_path from the associated object
  def get_directory
    # Assignment.find(self.node_object_id).directory_path
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.directory_path
  end

  # Gets the created_at from the associated object
  def get_creation_date
    # Assignment.find(self.node_object_id).created_at
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.created_at
  end

  # Gets the updated_at from the associated object
  def get_modified_date
    # Assignment.find(self.node_object_id).updated_at
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.updated_at
  end

  # Gets the course_id from the associated object
  def get_course_id
    # Assignment.find(self.node_object_id).course_id
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.course_id
  end

  # Returns true if the assignment is inside a course
  def belongs_to_course?
    !get_course_id.nil?
  end

  # Gets the instructor_id from the associated object
  def get_instructor_id
    # Assignment.find(self.node_object_id).course_id
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.instructor_id
  end

  # Gets the institution_id from the associated object
  def retrieve_institution_id
    # Course.find(self.node_object_id).course_id
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.instructor_id # This is just so that assignment_node has a matching def... it's not used
  end

  # Gets the private attribute from the associated object
  def get_private
    # Assignment.find(self.node_object_id).private
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.private
  end

  # Gets the max_team_size from the associated object
  def get_max_team_size
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.max_team_size
  end

  # Gets the is_intelligent from the associated object
  def get_is_intelligent
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.is_intelligent
  end

  # Gets the require_quiz from the associated object
  def get_require_quiz
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.require_quiz
  end
  
  # Get the number of quiz questions for the associated object
  def get_quiz_questions
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.num_quiz_questions
  end

  # Gets the require_quiz from the associated object
  def get_allow_suggestions
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.allow_suggestions
  end

   # Get the description for the associated object
  def get_spec_location
    @assign_node = Assignment.find(self.node_object_id) unless @assign_node
    @assign_node.spec_location
  end

  # Get the staggered deadline for the associated object
   def get_staggered_deadline
     @assign_node = Assignment.find(self.node_object_id) unless @assign_node
     @assign_node.staggered_deadline
   end

   #Get the microtask boolean for the associated object
   def get_microtask
     @assign_node = Assignment.find(self.node_object_id) unless @assign_node
     @assign_node.microtask
   end

   #Get the review_visible_to_all boolean for the associated object
   def get_review_visible
     @assign_node = Assignment.find(self.node_object_id) unless @assign_node
     @assign_node.reviews_visible_to_all
   end

   #Get the calibration flag for the associated object
   def get_calibration
     @assign_node = Assignment.find(self.node_object_id) unless @assign_node
     @assign_node.is_calibrated
   end

   #Get the reputation_algorithm for the associated object
   def get_reputation_algorithm
     @assign_node = Assignment.find(self.node_object_id) unless @assign_node
     @assign_node.reputation_algorithm
   end

   #Get the show_teammate_review flag for the associated object
   def get_teammate_review
     @assign_node = Assignment.find(self.node_object_id) unless @assign_node
     @assign_node.show_teammate_reviews
   end

   #Get the availibility flag for the associated object
   def get_availability
     @assign_node = Assignment.find(self.node_object_id) unless @assign_node
     @assign_node.availability_flag
   end

  # Gets any TeamNodes associated with this object
  def get_teams
    TeamNode.get(self.node_object_id)
  end
end
