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
          @user.make_active!
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

        r.post "add_cbe" do
          cbe_number = format_cbe_number(r.params["cbe_number"])

          unless cbe_number
            flash["error"] = "Malformed CBE number: #{r.params["cbe_number"]}"
            r.redirect "/users/#{@user.id}"
          end

          enterprise, publication = retrieve_enterprise_or_publication(cbe_number)

          if [enterprise, publication].all?(&:nil?)
            flash["error"] = "No enterprise of publication matching: #{r.params["cbe_number"]}"
            r.redirect "/users/#{@user.id}"
          end

          # AJAX action triggered by the "follow" button
          if r.headers["HX-Trigger"] == "follow_btn"
            full_width = tp.bool("full-width")

            if @user.follow_cbe_number?(cbe_number)
              return partials("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width, error: "Entity already followed by this user"})
            end

            # Entity exists in the local DB
            if enterprise
              if @user.add_enterprise(enterprise)
                return partial("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width})
              else
                return partial("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width, error: "Could not add the enterprise"})
              end
            elsif publication
              if @user.add_publication(publication)
                return partial("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width})
              else
                return partial("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width, error: "Could not add the enterprise"})
              end
            else
              flash["error"] = "Something has gone wrong while trying to follow CBE Number : #{cbe_number}"
              r.redirect "/users/#{@user.id}"
            end

          # Regular request (from the user page)
          else
            if @user.follow_cbe_number?(cbe_number)
              flash.now["error"] = "Entity already followed by this user"
              return view "user"
            end

            # Entity exists in the local DB
            if enterprise
              if @user.add_enterprise(enterprise)
                flash["success"] = "'#{enterprise.name}'' successfully added"
                r.redirect "/users/#{@user.id}"
              else
                flash.now["error"] = "Could not add '#{enterprise.name}'"
                rerturn view "user"
              end
            elsif publication
              if @user.add_publication(publication)
                flash["success"] = "'#{publication.entity_name}' successfully added"
                r.redirect "/users/#{@user.id}"
              else
                flash.now["error"] = "Could not add '#{enterprise.name}'"
                rerturn view "user"
              end
            else
              flash["error"] = "Something has gone wrong while trying to follow CBE Number : #{cbe_number}"
              r.redirect "/users/#{@user.id}"
            end
          end
        end

        r.post "delete_cbe" do
          cbe_number = format_cbe_number(r.params["cbe_number"])

          unless cbe_number
            flash["error"] = "Malformed CBE number: #{r.params["cbe_number"]}"
            r.redirect "/users/#{@user.id}"
          end

          enterprise, publication = retrieve_enterprise_or_publication(cbe_number)

          if [enterprise, publication].all?(&:nil?)
            flash["error"] = "No enterprise of publication matching: #{r.params["cbe_number"]}"
            r.redirect "/users/#{@user.id}"
          end

          if r.headers["HX-Trigger"] == "unfollow_btn"
            full_width = tp.bool("full-width")

            if enterprise && publication
              DB.transaction do
                @user.remove_publication(publication)
                @user.remove_enterprise(enterprise)
              end
              return partial("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width})

            elsif enterprise
              if @user.remove_enterprise(enterprise)
                return partial("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width})
              else
                return partials("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width, error: "could not remove CBE number"})
              end

            elsif publication
              if @user.remove_publication(publication)
                return partial("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width})
              else
                return partials("partials/follow_buttons", locals: {cbe_number: cbe_number, full_width: full_width, error: "could not remove CBE number"})
              end

            else
              flash["error"] = "Something has gone wrong while trying to remove CBE number : #{cbe_number}"
              r.redirect "/users/#{@user.id}"
            end

          else
            if enterprise && publication
              DB.transaction do
                @user.remove_publication(publication)
                @user.remove_enterprise(enterprise)
              end
              flash["success"] = "'#{enterprise.name}' successfully removed"
              r.redirect "/users/#{@user.id}"

            elsif enterprise
              if @user.remove_enterprise(enterprise)
                flash["success"] = "'#{enterprise.name}' successfully removed"
                r.redirect "/users/#{@user.id}"
              else
                flash.now["error"] = "'#{enterprise.name}' could not be removed"
                return view "user"
              end

            elsif publication
              if @user.remove_publication(publication)
                flash["success"] = "'#{publication.entity_name}' successfully removed"
                r.redirect "/users/#{@user.id}"
              else
                flash.now["error"] = "'#{@publication.entity_name}' could not be removed"
                return view "user"
              end

            else
              flash["error"] = "Something has gone wrong while trying to remove CBE Number : #{cbe_number}"
              r.redirect "/users/#{@user.id}"
            end
          end
        end

        # Merge CBE numbers from publications into enterprises
        r.post "merge-cbe-numbers" do
          if (report = @user.merge_cbe_numbers_from_publications!)
            flash["success"] = format_merge_report(report)
            r.redirect "/users/#{@user.id}"
          else
            flash.now["error"] = "No publications to merge"
            view "user"
          end
        end

        # Unfollow orphaned publications - which is mostly due to the fact that the entity has ceased to exist
        r.post "drop-orphaned-publications" do
          if (num_dropped = @user.drop_orphaned_publications!)
            flash["success"] = "#{num_dropped} orphaned #{num_dropped > 1 ? "publications" : "publication"} dropped"
            r.redirect "/users/#{@user.id}"
          else
            flash.now["error"] = "No orphaned publication dropped"
            view "user"
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
            view "results/index"
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
