class Templater

  def self.clean(path)
    return '' if path.nil?
    path.gsub(/[^\w\d_\/]/i, '').gsub(/(\/)+$/i, '')
  end

  def self.open(name)
    file_path = './app/templates/' + name + '.thtml'
    @file_data = File.read file_path
    @template_variables = {}

    include_partials
    save_variables
    create_variables

    create_tags
    create_ruby_data
    create_cycles
    create_comments

    # TODO: вложенные теги

    @file_data
  end


  private

  def self.partials_path
    './app/templates/partials/'
  end
  def self.comment_regex
    '(?<!##)'
  end


  def self.include_partials
    include_regexp = Regexp.new(comment_regex + '({include:([\w\d]+)})', Regexp::IGNORECASE)
    @file_data.gsub! include_regexp do
      file_name = '_' + $2.to_s + '.thtml'
      file_path = partials_path + file_name
      if File.exists? file_path
        File.read file_path
      else
        $1
      end
    end
  end

  def self.save_variables
    variable_regexp = Regexp.new(comment_regex + '{:=([\w\d]+)}\s*([^\n]*)', Regexp::IGNORECASE)
    matches = @file_data.scan variable_regexp
    matches.each do |match|
      key = match[0]
      value = match[1]
      @template_variables[key] = value
    end

    @file_data.gsub!(variable_regexp, '')
  end

  def self.create_variables
    variable_regexp = Regexp.new(comment_regex + '({:([\w\d]+)})', Regexp::IGNORECASE)
    @file_data.gsub! variable_regexp do
      @template_variables[$2] || $1
    end
  end




  def self.create_tags
    tag_regexp = Regexp.new(comment_regex + '{--([\w\d]+)}\s*([^\n]*)', Regexp::IGNORECASE)
    @file_data.gsub!(tag_regexp, '<\1>\2</\1>')
  end

  def self.create_cycles
    cycle_regexp = Regexp.new(comment_regex + '{---for:([\w]+):([\d]+);([\d]+)}(.*){---/for:\1}', Regexp::MULTILINE)
    @file_data.gsub! cycle_regexp do
      variable = $1
      cycle_body = $4 || ''

      result = ''
      for i in $2..$3
        regexp = Regexp.new("{-#{variable}}", 'mi')
        result += cycle_body.dup.gsub regexp, i.to_str
      end
      result
    end
  end

  def self.create_ruby_data
    @file_data.gsub! /(?<!##){#(.+?)(?=#})#}/mi do
      class_eval($1)
    end
  end

  def self.create_comments
    @file_data.gsub!(/##([^\s]+)/i, '\1')
  end

end
