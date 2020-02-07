class TeiToEs < XmlToEs
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
    # TODO what should default behavior be?
  end

  def category
    cat = get_text(@xpaths["category"])
    cat.length > 0 ? Datura::Helpers.normalize_space(cat) : "none"
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
    contribs = []
    @xpaths["contributors"].each do |xpath|
      eles = @xml.xpath(xpath)
      eles.each do |ele|
        contribs << {
          "id" => ele["id"],
          "name" => Datura::Helpers.normalize_space(ele.text),
          "role" => Datura::Helpers.normalize_space(ele["role"])
        }
      end
    end
    contribs.uniq
  end

  def data_type
    "tei"
  end

  def date(before=true)
    datestr = get_text(@xpaths["date"])
    Datura::Helpers.date_standardize(datestr, before)
  end

  def date_display
    get_text(@xpaths["date_display"])
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
    matched_format = nil
    # iterate through all the formats until the first one matches
    @xpaths["formats"].each do |type, xpath|
      text = get_text(xpath)
      matched_format = type if text && text.length > 0
    end
    matched_format
  end

  def image_id
    # Note: don't pull full path because will be pulled by IIIF
    images = get_list(@xpaths["image_id"])
    images[0] if images
  end

  def keywords
    get_list(@xpaths["keywords"])
  end

  def language
    get_text(@xpaths["language"])
  end

  def languages
    get_list(@xpaths["languages"])
  end

  def medium
    # Default behavior is the same as "format" method
    format
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
    get_text(@xpaths["publisher"])
  end

  def recipient
    eles = @xml.xpath(@xpaths["recipient"])
    eles.map do |p|
      {
        "id" => "",
        "name" => Datura::Helpers.normalize_space(p.text),
        "role" => "recipient"
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
    # copy this method into collection specific tei_to_es.rb
    # to return specific string or xpath as required
  end

  def source
    get_text(@xpaths["source"])
  end

  def subjects
    # TODO default behavior?
  end

  def subcategory
    subcat = get_text(@xpaths["subcategory"])
    subcat.length > 0 ? subcat : "none"
  end

  def text
    # handling separate fields in array
    # means no worrying about handling spacing between words
    text_all = []
    body = get_text(@xpaths["text"], false)
    text_all << body
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
    title_disp = get_text(@xpaths["titles"]["main"])
    if title_disp.empty?
      title_disp = get_text(@xpaths["titles"]["alt"])
    end
    title_disp
  end

  def title_sort
    Datura::Helpers.normalize_name(title)
  end

  def topics
    get_list(@xpaths["topic"])
  end

  def uri
    # override per collection
    # should point at the live website view of resource
  end

  def uri_data
    base = @options["data_base"]
    subpath = "data/#{@options["collection"]}/source/tei"
    "#{base}/#{subpath}/#{@id}.xml"
  end

  def uri_html
    base = @options["data_base"]
    subpath = "data/#{@options["collection"]}/output/#{@options["environment"]}/html"
    "#{base}/#{subpath}/#{@id}.html"
  end

  def works
    # TODO figure out how this behavior should look
  end
end
