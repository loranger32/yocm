module Yocm
  class App
    hash_branch("search") do |r|
      r.is do
        view "search"
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
            @publications = Publication.where(Sequel.lit("file_name LIKE ?", "#{input}%"))
                                       .limit(100)
                                       .all

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
            @denominations = Denomination.where(Sequel.lit("LOWER(denomination) LIKE LOWER(?)", "%#{input}%"))
                                         .where(type_of_denomination: "001")
                                         .limit(100)
                                         .all
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
          elsif !input.match?(/\A[\d|\.]{1,13}\z/)
            render(inline: "Invalid CBE Number")
          else
            @denominations = Denomination.where(Sequel.lit("enterprise_id LIKE ?", "#{partial_cbe_number(input)}%"))
                                         .limit(100)
                                         .all

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
