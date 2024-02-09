module Yocm
  class App
    hash_branch("zipcodes") do |r|
      r.is do
        view "zipcodes/zipcodes"
      end

      r.on do
        r.on "search-forms" do
          r.is "provinces" do
            @provinces = ZipCode.select(:province_fr).distinct.map(&:province_fr).compact.sort

            render "zipcodes/search-forms/provinces"
          end

          r.is "city" do
            render "zipcodes/search-forms/city"
          end

          r.is "village" do
            render "zipcodes/search-forms/village"
          end

          r.is "zipcodes" do
            render "zipcodes/search-forms/zipcode"
          end
        end

        r.on "tables" do
          r.is "all" do
            @zipcodes = ZipCode.all
            render "zipcodes/tables/all-zipcodes"
          end
        end

        r.on "filter" do

          r.is "zipcode" do
            input = tp.str("zipcode")

            if input.empty?
              render(inline: "")
            elsif !input.match?(/\A\d{1,4}\z/)
              render(inline: "Invalid input")
            else
              @zipcodes = ZipCode.where(code: /^#{input}/i).all
              if @zipcodes.empty?
                render(inline: "<p>No Results</p>")
              else
                render "zipcodes/tables/all-zipcodes"
              end
            end
          end

          r.is "city" do
            input = tp.str("city_name")

            if input.empty? || input.size <= 1
              render(inline: "")
            else
              @zipcodes = ZipCode.where(city_fr: /#{input}/i).all
              if @zipcodes.empty?
                render(inline: "<p>No Results</p>")
              else
                render "zipcodes/tables/all-zipcodes"
              end
            end
          end

          r.is "village" do
            input = tp.str("village_name")

            if input.empty? || input.size <= 1
              render(inline: "")
            else
              @zipcodes = ZipCode.where(village_fr: /#{input}/i).all
              if @zipcodes.empty?
                render(inline: "<p>No Results</p>")
              else
                render "zipcodes/tables/all-zipcodes"
              end
            end
          end

          r.is "province" do
            input = tp.str("province-select")

            @zipcodes = ZipCode.where(province_fr: input).all
            render "zipcodes/tables/all-zipcodes"
          end
        end
      end
    end
  end
end
