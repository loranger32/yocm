module Yocm
  module ViewHelpers
    def complete_list_class(referer, zip_errors_count)
      button_class = ""
      button_class += active_link(referer, "complete")
      button_class += " disabled" if zip_errors_count.zero?
      button_class
    end

    def pub_has_ocr_and_png?(publication)
      #return true
      File.exist?("app/public/#{publication.pub_date.to_s.delete("-")}/png/#{publication.file_name.sub("pdf", "png")}") &&
        File.exist?("app/public/#{publication.pub_date.to_s.delete("-")}/ocr/#{publication.file_name.sub("pdf", "txt")}")
    end

    def link_cbe(cbe_number)
      "https://kbopub.economie.fgov.be/kbopub/zoeknummerform.html?nummer=#{cbe_number}&actionLu=Recherche"
    end

    def link_mb(cbe_number)
      "https://www.ejustice.just.fgov.be/cgi_tsv/tsv_rech.pl?" \
        "language=fr&btw=#{cbe_number.delete(".")}&liste=Liste"
    end

    def link_publication(publication)
      "/#{publication.pub_date.to_s.delete('-')}/pdf/#{publication.file_name}"
    end

    def link_to_png(publication)
      "/#{publication.pub_date.to_s.delete("-")}/png/#{publication.file_name.sub(".pdf", ".png")}"
    end

    def date_clean(date)
      if date.is_a? Date
        date.strftime("%e %B %Y")
      elsif date.match?(/\d{4}-\d{2}-\d{2}/)
        Date.parse(date).strftime("%e %B %Y")
      end
    end

    def zip_display(zip_code)
      zip_code == "0000" ? "" : zip_code
    end

    def count_all_from_date(date)
      Publication.count_all_from_date(date)
    end

    def count_complete_from_date(date)
      Publication.count_complete_from_date(date)
    end

    def count_probably_new_from_date(date)
      Publication.count_probably_new_from_date(date)
    end

    def count_zip_errors_from_date(date)
      Publication.count_zip_errors_from_date(date)
    end

    def count_cbe_errors_from_date(date)
      Publication.count_cbe_errors_from_date(date)
    end

    def count_incomplete_from_date(date)
      Publication.count_incomplete_from_date(date)
    end

    def back_to_list_link(pub_date, referer)
      if referer.nil? || referer.empty?
        "/publications/#{pub_date}"
      else
        "/publications/#{pub_date}/#{referer}"
      end
    end

    def active_link(referer, actual_link = nil)
      referer == actual_link ? "active" : ""
    end

    def publications_list_link(pub_date, referer, sort_by, order)
      base_path = "/publications/#{pub_date}"
      base_path << "/#{referer}" unless referer.nil? || referer.empty?
      base_path << "?sort=#{sort_by}&order=#{order}"
    end

    def link_to_first_zip_error_publication(pub_date)
      publication = Publication.next_zip_error_publication(pub_date)

      "/publications/#{pub_date}/#{publication.file_name}" if publication
    end

    def all_publications_complete?(pub_date)
      Publication.from_date(pub_date).where(zip_code_id: 1).empty?
    end

    def all_villages_from(zip_code)
      ZipCode.where(code: zip_code.code).map(:village_fr).join(", ")
    end

    def all_zip_code_numbers_of(user)
      user.zip_codes.map(&:code).join(", ")
    end

    def is_active?(user)
      @active_user == user
    end

    def publications_matching_zip_code(publications, zip_code)
      publications.select { |pub| pub.zip_code_id == zip_code.id }
    end

    def ratio_complete_all(complete, all)
      ((complete.to_f / all.to_f) * 100).to_i.to_s + "%"
    end

    def pub_day_row_class(pub_date)
      if all_publications_complete?(pub_date)
        "table-success"
      else
        "table-danger"
      end
    end

    def pub_form_visibility(pub_not_ok:, edit_mode:)
      "invisible" unless pub_not_ok || edit_mode
    end

    def publication_row_class(publication)
      row_class = "table-"
      row_class += if publication.probably_new
        "primary"
      elsif !publication.complete?
        "danger"
      else
        "success"
      end
    end

    def link_public_accounts(cbe_number)
      ref = cbe_number.delete(".")
      "https://consult.cbso.nbb.be/consult-enterprise/#{ref}"
    end

    def tab_title(title)
      title.nil? ? "Yocm - GUI" : "Yocm - #{title}"
    end

    def truncate(str, target_length)
      return str if str.length <= target_length
      str[0..target_length - 3] + "..."
    end

    def zip_error_list_class(referer, zip_errors_count)
      button_class = ""
      button_class += active_link(referer, "zip-code-errors")
      button_class += " disabled" if zip_errors_count.zero?
      button_class
    end
  end
end
