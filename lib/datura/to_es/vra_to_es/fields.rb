class VraToEs < XmlToEs
  # Note to add custom fields, use "assemble_collection_specific" from request.rb
  # and be sure to either use the _d, _i, _k, or _t to use the correct field type

  ##########
  # FIELDS #
  ##########

  def id
    @id
  end

  def id_dc
    # TODO use api path from config or something?
    "https://cdrhapi.unl.edu/doc/#{@id}"
  end

  def annotations_text
    # TODO default behavior?
  end

  def category
    # TODO default behavior?
  end

  # note this does not sort the creators
  def creator
    creators = get_list(@xpaths["creators"])
    creators.map { |c| { "name" => Datura::Helpers.normalize_space(c) } }
  end

  # returns ; delineated string of alphabetized creators
  def creator_sort
    get_text(@xpaths["creators"])
  end

  def collection
    @options["collection"]
  end

  def collection_desc
    @options["collection_desc"] || @options["collection"]
  end

  def contributor
    contrib_list = []
    contributors = @xml.xpath(@xpaths["contributors"])
    contributors.each do |ele|
      contrib_list << {
        "id" => "",
        "name" => Datura::Helpers.normalize_space(ele.xpath("name").text),
        "role" => Datura::Helpers.normalize_space(ele.xpath("role").text)
      }
    end
    contrib_list
  end

  def data_type
    "vra"
  end

  def date(before=true)
    datestr = get_text(@xpaths["dates"]["earliest"])
    Datura::Helpers.date_standardize(datestr, before)
  end

  def date_display
    get_text(@xpaths["dates"]["display"])
  end

  def date_not_after
    date(false)
  end

  def date_not_before
    date(true)
  end

  def description
    # Note: override per collection as needed
  end

  def format
    # iterate through all the formats until the first one matches
    get_text(@xpaths["format"])
  end

  def image_id
    # TODO only needed for Cody Archive, but put generic rules in here
  end

  def keywords
    get_list(@xpaths["keywords"])
  end

  def language
    # TODO need some examples to use
    # look for attribute anywhere in whole text and add to array
  end

  def languages
    # TODO
  end

  def medium
    # iterate through all the formats until the first one matches
    get_text(@xpaths["format"])
  end

  def person
    # TODO will need some examples of how this will work
    # and put in the xpaths above, also for attributes, etc
    # should contain name, id, and role
    eles = @xml.xpath(@xpaths["person"])
    eles.map do |p|
      {
        "id" => "",
        "name" => Datura::Helpers.normalize_space(p.text),
        "role" => Datura::Helpers.normalize_space(p["role"])
      }
    end
  end

  def people
    @json["person"].map { |p| Datura::Helpers.normalize_space(p["name"]) }
  end

  def places
    get_list(@xpaths["places"])
  end

  def publisher
    get_list(@xpaths["publisher"])
  end

  def recipient
    eles = @xml.xpath(@xpaths["recipient"])
    eles.map do |p|
      {
        "id" => "",
        "name" => Datura::Helpers.normalize_space(p.text),
        "role" => Datura::Helpers.normalize_space(p["role"]),
      }
    end
  end

  def rights
    # Note: override by collection as needed
    "All Rights Reserved"
  end

  def rights_holder
    get_text(@xpaths["rights_holder"])
  end

  def rights_uri
    # by default collections have no uri associated with them
    # copy this method into collection specific vra_to_es.rb
    # to return specific string or xpath as required
  end

  def source
    # TODO default behavior?
  end

  def subcategory
    # TODO default behavior?
  end

  def subjects
    # TODO default behavior?
  end

  def text
    # handling separate fields in array
    # means no worrying about handling spacing between words
    text_all = []
    text_all << get_text(@xpaths["text"], false)
    # TODO: do we need to preserve tags like <i> in text? if so, turn get_text to true
    # text_all << CommonXml.convert_tags_in_string(body)
    text_all += text_additional
    Datura::Helpers.normalize_space(text_all.join(" "))
  end

  def text_additional
    # Note: Override this per collection if you need additional
    # searchable fields or information for collections
    # just make sure you return an array at the end!

    [ title ]
  end

  def title
    get_text(@xpaths["title"])
  end

  def title_sort
    Datura::Helpers.normalize_name(title)
  end

  def topics
    # TODO default behavior?
  end

  def uri
    # override per collection
    # should point at the live website view of resource
  end

  def uri_data
    base = @options["data_base"]
    subpath = "data/#{@options["collection"]}/source/vra"
    "#{base}/#{subpath}/#{@id}.xml"
  end

  def uri_html
    base = @options["data_base"]
    subpath = "data/#{@options["collection"]}/output/#{@options["environment"]}/html"
    "#{base}/#{subpath}/#{@id}.html"
  end

  def works
    # TODO default behavior?
  end
end
