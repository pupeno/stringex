module LuckySneaks
  module ActsAsUrl # :nodoc:
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods # :doc:
      # Creates a callback to automatically create an url-friendly representation
      # of the <tt>attribute</tt> argument. Example:
      # 
      #   act_as_url :title
      # 
      # will use the string contents of the <tt>title</tt> attribute
      # to create the permalink. The default attribute for <tt>acts_as_url</tt>
      # is <tt>url</tt> but can be changed in the options hash. Available options are:
      # 
      # <tt>:url_attribute</tt>:: The name of the attribute to use for storing the generated url string.
      #                           Default is <tt>:url</tt>
      # <tt>:scope</tt>:: The name of model attribute to scope unique urls to. There is no default here.
      # <tt>:sync_url</tt>:: If set to true, the url field will be updated when changes are made to the
      #                      attribute it is based on. Default is false.
      def acts_as_url(attribute, options = {})
        cattr_accessor :attribute_to_urlify
        cattr_accessor :scope_for_url
        cattr_accessor :url_attribute # The attribute on the DB
        
        if options[:sync_url]
          before_validation :ensure_unique_url
        else
          before_validation_on_create :ensure_unique_url
        end

        self.attribute_to_urlify = attribute
        self.scope_for_url = options[:scope]
        self.url_attribute = options[:url_attribute] || "url"
      end
    end
      
  private
    def ensure_unique_url
      url_attribute = self.class.url_attribute
      base_url = self.send(self.class.attribute_to_urlify).to_s.to_url
      conditions = ["#{url_attribute} = ?", base_url]
      unless new_record?
        conditions.first << " and id != ?"
        conditions << id
      end
      if self.class.scope_for_url
        conditions.first << " and #{self.class.scope_for_url} = ?"
        conditions << send(self.class.scope_for_url)
      end
      url_owners = self.class.find(:all, :conditions => conditions)
      if url_owners.size > 0
        n = 1
        while url_owners.detect{|u| u.send(url_attribute) == "#{base_url}-#{n}"}
          n = n.succ
        end
        write_attribute url_attribute, "#{base_url}-#{n}"
      else
        write_attribute url_attribute, base_url
      end
    end
  end
end