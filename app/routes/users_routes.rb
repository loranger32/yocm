module Yocm
  class App
    hash_branch("users") do |r|
      r.is do
        r.get do
          @users = User.all

          view "users"
        end

        r.post do
          email = tp.nonempty_str("email")
          new_user = User.new(email: email)

          if new_user.valid?
            new_user.save
            flash["success"] = "User successfully created"
          else
            flash["error"] = new_user.errors.full_messages.join(", ")
          end

          r.redirect "/users"
        end
      end

      r.is "results" do
        if @active_user
          r.redirect "/users/#{@active_user.id}/results"
        else
          flash["error"] = "No active user. Please set one or select a specific user to access its results"
          r.redirect "/users"
        end
      end

      r.on Integer do |id|
        @user = User[id]

        unless @user
          response.status = 404
          r.halt
        end

        @pub_dates = Publication.pub_dates

        ### User Management
        r.is do
          r.get do
            view "user"
          end

          r.post do
            @user.destroy
            flash["success"] = "User #{@user.email} successfully deleted"
            r.redirect "/users"
          end
        end

        r. post "activate" do
          r.session["active_user_id"] = @user.id
          flash[:success] = "User #{@user.email} is now the active user"
          r.redirect "/users/#{@user.id}"
        end

        r.post "add_zip" do
          # Validate zip format
          unless r.params["new_zip"].match?(/\A\d{4}\z/)
            flash.now["error"] = "Not a zip code"
            return view "user"
          end

          new_zip = ZipCode.where(code: r.params["new_zip"]).first

          unless new_zip
            flash.now["error"] = "Not a valid zip code"
            return view "user"
          end

          if @user.zip_codes.include?(new_zip)
            flash.now["error"] = "Zip code already registered"
            return view "user"
          end

          if @user.add_zip_code(new_zip)
            flash["success"] = "New zip code added"
            r.redirect "/users/#{@user.id}"
          end
        end

        r.post "delete_zip" do
          unless r.params["zip_code"].match?(/\A\d{4}\z/)
            flash.now["error"] = "Something went wrong when trying to delete zip code"
            return view "user_edit"
          end

          old_zip = ZipCode.where(code: r.params["zip_code"]).first
          if old_zip && @user.remove_zip_code(old_zip)
            flash["success"] = "Zip code deleted"
            r.redirect "/users/#{@user.id}"
          else
            flash.now["error"] = "Could not delete zip code"
            return view "users"
          end
        end

        r.post "add_enterprise" do
          cbe_number = r.params["cbe_number"].strip

          unless (new_enterprise = retrieve_enterprise_from_cbe_number_input(cbe_number))
            flash.now["error"] = "Invalid cbe number provided"
            return view "user"
          end

          if @user.follow_cbe_number?(new_enterprise.id)
            flash.now["error"] = "Enterprise already followed by this user"
            return view "user"
          end

          if @user.add_enterprise(new_enterprise)
            if r.headers["HX-Trigger"] == "follow_btn"
              return partial("partials/unfollow_button", locals: {cbe_number: new_enterprise.id})
            else
              flash["success"] = "Enterprise has been added"
              r.redirect "/users/#{@user.id}"
            end
          else
            if r.headers["HX-Trigger"] == "follow_btn"
              # Temporary error message
              return render(inline: "<p>An error has occurred</p>")
            else
              flash.now["error"] = "Could not add enterprise"
              return view "user"
            end
          end
        end

        r.post "delete_enterprise" do
          cbe_number = r.params["cbe_number"].strip

          unless (old_enterprise = retrieve_enterprise_from_cbe_number_input(cbe_number))
            flash.now["error"] = "Invalid CBE number provided"
            return view "user"
          end

          if @user.remove_enterprise(old_enterprise)
            if r.headers["HX-Trigger"] == "unfollow_btn"
              return partial("partials/follow_button", locals: {cbe_number: old_enterprise.id})
            else
              flash["success"] = "Enterprise deleted"
              r.redirect "/users/#{@user.id}"
            end
          else
            if r.headers["HX-Trigger"] == "unfollow_btn"
              # Temporary error message
              return render(inline: "<p>An error has occurred</p>")
            else
              flash.now["error"] = "Could not delete enterprise"
              return view "user"
            end
          end
        end

        ### User's results
        r.on "results" do
          zip_code_ids = @user.zip_codes.sort_by(&:code).map(&:id)
          enterprises_ids = @user.enterprises.sort_by(&:id).map(&:id)

          r.is do
            @results_data = []
            @pub_dates = Publication.select(:pub_date).distinct.order_by(:pub_date).reverse.select_map(:pub_date)
            @pub_dates.each do |pub_date|
              matching_zip_codes_count = Publication.daily_publications_matching_zip_codes_count_for(zip_code_ids, pub_date)
              matching_enterprises_count = Publication.daily_publications_matching_enterprises_count_for(enterprises_ids, pub_date)
              @results_data << {pub_date: pub_date,
                                matching_zip_code_count: matching_zip_codes_count,
                                matching_enterprises_count: matching_enterprises_count}
            end
            view "results/results"
          end

          r.on String do |pub_date|
            unless valid_pub_date?(pub_date)
              response.status = 404
              r.halt
            end

            @pub_date = pub_date

            r.on "zipcodes" do
              zip_codes = @user.zip_codes.map(&:code)

              if zip_codes.empty?
                @no_registered_zip_codes = true
                return view("results/zip_code_results")
              end

              r.is do
                r.redirect "/users/#{@user.id}/results/#{@pub_date}/zipcodes/#{zip_codes.first}"
              end

              r.is String do |zip_code|
                zip_code_ids = @user.zip_codes.sort_by(&:code).map(&:id)

                @matching_codes_count = Publication.matching_zip_codes_count_for_day_and_codes(zip_code_ids, @pub_date)
                @matching_codes = @matching_codes_count.map {_1[0] }
                @total_matching_publications = Publication.daily_publications_matching_zip_codes_count_for(zip_code_ids, pub_date)
                @current_zip_code = ZipCode.where(code: zip_code).first

                unless @current_zip_code
                  response.status = 404
                  r.halt
                end

                @publications = Publication.daily_publications_matching_zip_codes_for(@current_zip_code.id, pub_date)
                @enterprises = @publications.map(&:enterprise)
                
                # Cannot use the enterprise partial : new entity are not present in the local DB
                view "results/zip_code_results"
              end
            end

            r.is "enterprises" do
              @enterprises = Publication.daily_publications_matching_enterprises_for(enterprises_ids, @pub_date).map(&:enterprise).uniq

              view "results/enterprise_results"
            end
          end
        end
      end
    end
  end
end
