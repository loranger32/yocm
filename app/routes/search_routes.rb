module Yocm
  class App
    hash_branch("search") do |r|
      r.is do
        view "search"
      end

      r.is "on-file-name" do
        file_name = tp.nonempty_str!("file_name")

        # There is a valid file name as query parameter
        if file_name&.match?(/\A\d{8}.pdf\z/)
          @publication = Publication.where(file_name: file_name).first
          r.redirect "/publications/#{@publication.pub_date}/#{@publication.file_name}"

        # There is an invalid file name or no file_name as query parameter
        else
          flash.now["error"] = "Not a valid file name"
          view "search"
        end
      end

      r.is "on_cbe_number" do
        @cbe_number = tp.nonempty_str!("cbe_number")

        if valid_cbe_number?(@cbe_number)
          r.redirect "/enterprises/#{@cbe_number}"
        else
          flash.now["error"] = "Not a valid cbe number"
          view "search"
        end
      end

      r.on "search-form" do
        r.is "file-name" do
          render "search/forms/file-name"
        end

        r.is "entity-name" do
          render "search/forms/entity-name"
        end

        r.is "cbe-number" do
          render "search/forms/cbe-number"
        end

        r.on "table" do
          r.is "file-name" do
            render "search/tables/file-name"
          end

          r.is "entity-name" do
            render "search/tables/entity-name"
          end

          r.is "cbe-number" do
            render "search/tables/cbe-number"
          end
        end
      end

      r.on "filter" do
        r.is "file-name" do
          input = tp.str("file_name")

          if input.empty?
            render(inline: "")
          elsif !input.match?(/\A\d{1,8}(\.pdf)?\z/)
            render(inline: "Invalid File Name")
          else
            @publications = Publication.where(file_name: /\A#{input}/).limit(100).all
            if @publications.empty?
              render(inline: "<p>No Results</p>")
            else
              @max_results_size = @publications.count == 100
              render "search/tables/file-name"
            end
          end
        end

        r.is "entity-name" do
          input = tp.str("entity_name")

          if input.empty?
            render(inline: "")
          else
            @denominations = Denomination.where(Sequel.lit("denomination ILIKE ?", "%#{input}%")).limit(100).all
            if @denominations.empty?
              render(inline: "<p>No Results</p>")
            else
              @max_results_size = @denominations.count == 100
              render "search/tables/entity-name"
            end
          end
        end

        r.is "cbe-number" do
          input = tp.str("cbe_number")

          if input.empty?
            render(inline: "")
          elsif !input.match?(/\A[\d|.]{1,13}\z/)
            render(inline: "Invalid CBE Number")
          else
            @denominations = Denomination.where(enterprise_id: /\A#{partial_cbe_number(input)}/).limit(100).all
            if @denominations.empty?
              render(inline: "<p>No Results</p>")
            else
              @max_results_size = @denominations.count == 100
              render "search/tables/cbe-number"
            end
          end
        end
      end
    end
  end
end
