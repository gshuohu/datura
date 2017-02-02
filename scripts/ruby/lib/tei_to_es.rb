require "nokogiri"
require_relative "helpers.rb"
require_relative "tei_to_es/fields.rb"
require_relative "tei_to_es/xpaths.rb"

#########################################
# NOTE:  DO NOT EDIT THIS FILE!!!!!!!!! #
#########################################
#   (unless you are a CDRH dev and then you may do so very cautiously)
#   this file provides defaults for ALL of the projects included
#   in the API and changing it could alter dozens of sites unexpectedly!
# PLEASE RUN LOADS OF TESTS AFTER A CHANGE BEFORE PUSHING TO PRODUCTION

# HOW DO I CHANGE XPATHS?
#   You may add or modify xpaths in each project's tei_to_es.rb file
#   located in the projects/<project>/scripts directory

# HOW DO I CHANGE FIELD CONTENT?
#   You may need to alter an xpath, but otherwise you may also
#   copy paste the field defined in tei_to_es/fields.rb and change
#   it as needed. If you are dealing with something particularly complex
#   you may need to consult with a CDRH dev for help

module TeiToEs

  # getter for json response object
  def self.create_json file, params={}
    @file = file
    @xml = create_xml_object
    @id = file.filename(false)
    @options = params

    # create an object that with hold all of the ES documents
    # and put the "main" one in immediately
    @json = []
    @json << assemble_json

    # iterate through any specified sub-doc xpaths and add to json
    docs = get_docs
    docs.each do |doc|
      @json << self.assemble_subdoc_json(doc)
    end
    return @json
  end

  # xpaths by which a file should be divided into multiple docs
  # for example, a personography file divides on "//person"
  # this system may need to be made far more robust in the near future
  @subdoc_xpaths = [
    "//listPerson/person"
  ]

  # TODO a lot of stuff comes in from the specific params objects
  # but those will be very different for the new api schema
  # so I'm just waiting on that for now

  def self.create_xml_object
    file_xml = File.open(@file.file_location) { |f| Nokogiri::XML f }
    # TODO is this a good idea?
    file_xml.remove_namespaces!
    return file_xml
  end

  def self.get_docs
    # get all of the subdocs based on the xpaths
    docs = []
    @subdoc_xpaths.each do |xpath|
      docs += @xml.xpath(xpath)
    end
    return docs
  end


  def self.assemble_json
    json = {}

    # TODO might put these into methods themselves
    # so that a project could override only a clump of fields
    # rather than all?
    # Note: the above might only matter if ES can't handle nil
    # values being sent, because otherwise they could just override
    # the field behavior to be blank

    ###############
    # identifiers #
    ###############
    # cannot add this manually, have to do it via url
    # json["_type"] = shortname
    json["cdrh-identifier"] = id
    json["dc-identifier"] = id_dc

    ##############
    # categories #
    ##############
    json["cdrh-category"] = category
    json["cdrh-subcategory"] = subcategory
    json["cdrh-data_type"] = "tei"
    json["cdrh-project"] = project
    json["cdrh-shortname"] = shortname
    # json["dc-subject"]

    #############
    # locations #
    #############

    # TODO check, because I'm not sure the schema
    # lists the urls that we actually want to use
    # earlywashingtondc.org vs cdrhmedia, etc
    # json["cdrh-uri"]
    # json["cdrh-uri_data"]
    # json["cdrh-uri_html"]
    # json["cdrh-fig_location"]
    # json["cdrh-image_id"]

    ###############
    # description #
    ###############
    json["cdrh-title_sort"] = title_sort
    json["dc-title"] = title
    json["dc-description"] = description
    # json["cdrh-topics"]
    # json["dcterms-alternative"]

    ##################
    # other metadata #
    ##################
    json["dc-format"] = format
    json["dc-language"] = language
    # json["dc-relation"]
    # json["dc-type"]
    # json["dcterms-extent"]
    json["dcterms-medium"] = format

    #########
    # dates #
    #########
    json["cdrh-date_display"] = date_display
    json["dc-date"] = date
    json["cdrh-date_not_before"] = date
    json["cdrh-date_not_after"] = date false

    ####################
    # publishing stuff #
    ####################
    json["cdrh-rights_uri"] = rights_uri
    json["dc-publisher"] = publisher
    json["dc-rights"] = rights
    json["dc-source"] = source
    json["dcterms-rights_holder"] = rights_holder

    ##########
    # people #
    ##########
    json["cdrh-creator_sort"] = creator_sort
    json["cdrh-people"] = person_sort
    # container fields
    json["cdrh-person"] = person
    json["dc-contributor"] = contributors
    json["dc-creator"] = creator

    ###########
    # spatial #
    ###########
    # TODO not sure about the naming convention here?
    # TODO has place_name, coordinates, id, city, county, country,
    # region, state, street, postal_code
    # json["dcterms-coverage.spatial"]

    ##############
    # referenced #
    ##############
    json["cdrh-keywords"] = keywords
    json["cdrh-places"] = places
    json["cdrh-works"] = works

    #################
    # text searches #
    #################
    json["cdrh-annotations"] = annotations
    json["cdrh-text"] = text
    # json["dc-abstract"]

    project_specific_fields

    return json
  end

  # TODO some problems with hurriedly throwing subdocs in here
  # you can't use the normal fields down below because the majority
  # of them pull info straight from @xml
  # this could be mitigated if the xpaths sent use the index of the doc
  # like blah/person[1]/xpath but that seems like a dangerous
  # idea to be separating the data and the paths like that
  # for now, since this is just a proof of concept I'm going
  # to hardcode stuff, sad day
  # possibly all docs could be made into a class and then
  # subclasses spun off of that to allow modification to behavior
  # without affecting more docs following after subdocs?
  def self.assemble_subdoc_json doc
    json = {}
    doc_identifier = doc["id"]
    id = "#{@id}_#{doc_identifier}"
    json["cdrh-identifier"] = id
    # json["dc-identifier"] = "todo"

    json["category"] = "Life"
    json["subCategory"] = "Personography"
    json["cdrh-data_type"] = "tei"
    json["cdrh-project"] = project
    json["cdrh-shortname"] = shortname

    json["dc-title"] = doc.xpath("./persName[@type='display']").text
    json["cdrh-title_sort"] = Common.normalize_name(json["dc-title"])
    # more fields would be contributor, people, description, text, etc
    return json
  end


  ###########
  # HELPERS #
  ###########

  # see helpers.rb's Common module for methods imported from common.xsl

  # get the value of one of the xpaths listed at the top
  # Note: if the xpath returns multiple values they will be squished together
  # TODO should we make it so that this can optionally look for more than one
  # result?

  # get_list
  #   can pass it a string xpath or array of xpaths
  # returns an array with the html value in xpath
  def self.get_list xpaths, keep_tags=false
    xpaths = xpaths.class == Array ? xpaths : [xpaths]
    return get_xpaths xpaths, keep_tags
  end

  # get_text
  #   can pass it a string xpath or array of xpaths
  #   can optionally set a delimiter, otherwise ;
  # returns a STRING
  # if you want a multivalued result, please refer to get_list
  def self.get_text xpaths, keep_tags=false, delimiter=";"
    # ensure all xpaths are an array before beginning
    xpaths = xpaths.class == Array ? xpaths : [xpaths]
    list = get_xpaths xpaths, keep_tags
    sorted = list.sort
    return sorted.join("#{delimiter} ")
  end

  # Note: Recommend that project team do NOT use this method directly
  #   please use get_list or get_text instead
  # keep_tags true will convert tags like <hi> to <em>
  #   use this wisely, as it causes performance issues
  # keep_tags false removes ALL tags from selected xpath
  def self.get_xpaths xpaths, keep_tags=false
    list = []
    xpaths.each do |xpath|
      contents = @xml.xpath(xpath)
      contents.each do |content|
        text = ""
        if keep_tags
          converted = Common.convert_tags(content)
          text = converted.inner_html
        else
          text = content.text
        end
        text = Common.squeeze(text)
        if text.length > 0
          list << text
        end
      end
    end
    return list.uniq
  end

end
