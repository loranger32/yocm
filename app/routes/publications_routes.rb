module Yocm
  class App
    hash_branch("publications") do |r|

      #################
      # VIEW ALL DAYS #
      #################
      r.is do
        current_page = tp.pos_int("page", 1)

        @pub_dates_ds = DB[:publications]
          .select(:pub_date)
          .distinct
          .order_by(:pub_date)
          .reverse
          .extension(:pagination)
          .paginate(current_page, 20)

        @pub_dates = @pub_dates_ds.select_map(:pub_date)

        view "index"
      end

      #########################
      # DELETE PUBLICATION(S) #
      #########################
      r.on "delete" do

        @target_date = tp.str("date")
        unless @target_date.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          flash["error"] = "Invalid date format - delete aborted"
          r.redirect "/publications"
        end

        # Delete all pubs before date
        r.post "many" do

          all_pub_dirs = Dir[File.join(opts[:root], "public", "*")].reject { _1.end_with?("images") }
          # directory name ends with 8 digits (date)
          target_pub_dirs = all_pub_dirs.select { _1[-8..-1] <= @target_date.delete("-") }

          # file name format is report_YYYYMMDD.html
          all_report_files = Dir[File.join("yocm", "data", "reports", "report_*.html")]
          target_report_files = all_report_files.select { _1[-13..-6] <= @target_date.delete("-") }

          # file name format is YYYYMMDD.xml
          all_index_files = Dir[File.join("yocm", "data", "index", "*.xml")]
          target_index_files = all_index_files.select { _1[-12..-5] <= @target_date.delete("-") }

          if (num_delete = Publication.where(Sequel[:pub_date] <= @target_date).delete) > 0
            FileUtils.rm_r(target_pub_dirs, secure: true)
            target_report_files.each { File.delete(it) }
            target_index_files.each { File.delete(it) }

            flash["success"] = "#{num_delete} publications deleted from #{@target_date}"
          else
            flash["error"] = "No publication deleted - check the date parameter"
          end

          r.redirect "/publications"
        end

        # Delete on specific day
        r.post do
          if (num_delete = Publication.where(pub_date: @target_date).delete) > 0
            FileUtils.rm_r(File.join(opts[:root], "public", @target_date.delete("-")), secure: true)

            # Delete corresponding report and index files
            report_file = File.join("yocm", "data", "reports", "report_#{@target_date.delete("-")}.html")
            index_file = File.join("yocm", "data", "index", "#{@target_date.delete("-")}.xml")

            File.delete(report_file) if File.exist?(report_file)
            File.delete(index_file) if File.exist?(index_file)

            flash["success"] = "#{num_delete} publications from #{@target_date} deleted"
          else
            flash["error"] = "No publication deleted - check the date param"
          end

          r.redirect "/publications"
        end
      end

      ##################
      # PARTICULAR DAY #
      ##################
      r.on String do |pub_date|

        unless valid_pub_date?(pub_date)
          response.status = 404
          r.halt
        end

        @pub_date = pub_date

        publications_ds = Publication.where(pub_date: pub_date)

        # Show all publications of selected day
        r.is do
          @publications = sort_publications(publications_ds, r.params["sort"], r.params["order"])

          view "publications"
        end

        # Show only new publications of selected day
        r.is "new" do
          @publications = sort_publications(publications_ds.where(probably_new: true),
            r.params["sort"],
            r.params["order"])
          @referer = "new"

          view "publications"
        end

        # Show only complete publications of selected day
        r.is "complete" do
          @publications = sort_publications(publications_ds.exclude(zip_code_id: 1),
            r.params["sort"],
            r.params["order"])
          @referer = "complete"

          view "publications"
        end

        # Show only publications with zip errors of selected day
        r.is "zip-code-errors" do
          @publications = sort_publications(publications_ds.where(zip_code_id: 1),
            r.params["sort"],
            r.params["order"])
          @referer = "zip-code-errors"

          view "publications"
        end

        #################################
        # INDIVIDUAL PUBLICATION BRANCH #
        #################################
        r.on String do |file_name|
          unless Publication.valid_pub_file_name?(file_name)
            response.status = 404
            r.halt
          end

          @publication = Publication.where(file_name: file_name).first
          @enterprise = Enterprise[@publication.cbe_number]

          r.is do
            @batch_mode = tp.bool("batch_mode")

            # Show Publication
            r.get do
              @modify_pub = tp.bool("modify_pub")
              @referer = r.params["referer"]
              @enterprise_id = @publication.cbe_number

              view "publication"
            end

            # Update Publication
            r.post do
              zip_code = tp.str("zip_code")

              unless valid_zip_code?(zip_code)
                flash["error"] = "Invalid zip code submitted"
                r.redirect
              end

              @publication.zip_code_id = ZipCode.where(code: zip_code).first.id

              publication_is_saved = @publication.save

              if publication_is_saved
                flash["success"] = "Publication successfully modified"
                unless Enterprise[@publication.cbe_number]
                  flash["warning"] = "No enterprise found with the CBE number"
                  flash["file_name"] = file_name
                  flash["pub_date"] = pub_date
                end
              else
                flash.now["error"] = "Something went wrong"
                return view "publication"
              end

              # handle the batch mode options
              if @batch_mode
                @publication = Publication.next_zip_error_publication(@pub_date)
                if @publication
                  @referer = "zip-code-errors"
                  @batch_zip = true
                  @modify_pub = true

                  r.redirect("/publications/#{@publication.pub_date}/#{@publication.file_name}" +
                            "?modify_pub=#{@modify_pub}&referer=#{@referer}&batch_mode=#{r.params['batch_mode']}")
                else
                  # When done, done screen gives enough feed-back by itself.
                  flash["success"] = nil
                  flash["warning"] = nil

                  return view "done"
                end
              else
                r.redirect
              end
            end
          end

          # OCR Debug Mode
          r.is "debug" do
            r.get do
              if tp.str("retry") == "true"
                @ocr_text = RTesseract.new("app/public/#{link_to_png(@publication)}", lang: "fra+nld", psm: 6).to_s
              else
                @ocr_text = File.read("app/public/#{link_ocr_text(@publication)}")
              end

              if tp.str("test-new-regexp") == "true"
                @regexp_used = Regexp.new(tp.str("new-regexp"), tp.str("new-regexp-opts"))
              else
                @regexp_used = retrieve_regexp(@ocr_text)
              end

              @current_regexp_opts = @regexp_used.to_s.scan(/\?([mix]+)[-:]/).flatten.first
              @current_regexp = @regexp_used.to_s.scan(/\(\?[mix]+[-mix]+:(.+)\)/).flatten.first
              @captured_text = @ocr_text.match(@regexp_used)
              @matches = @captured_text && @captured_text[1]&.scan(/[1-9]\d{3}/)

              view "debug"
            end
          end
        end
      end
    end
  end
end
