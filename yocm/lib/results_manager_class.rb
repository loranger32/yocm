module Yocm
  class ResultsManager
    ZipCodeResult = Data.define(:code, :num_matches)
    ZipCodeResults = Data.define(:match, :matching)

    EnterpriseResult = Data.define(:cbe_number, :denomination)
    EnterpriseResults = Data.define(:match, :matching)

    # user is a User model
    # target date is a Date instance
    def initialize(user, target_date)
      @user = user
      @target_date = target_date
    end

    def zip_code_results
      user_zip_codes = @user.zip_codes.map(&:id)
      zip_codes_count = Publication.daily_publications_matching_zip_codes_for(user_zip_codes, @target_date).map { ZipCode[_1.zip_code_id].code }.tally
      matching = zip_codes_count.map { |code, matches| ZipCodeResult.new(code: code, num_matches: matches) }
      ZipCodeResults.new(match: true, matching: matching)
    end

    def enterprise_results
      user_cbe_numbers = @user.enterprises.map(&:id)
      matching_publications = Publication.daily_publications_matching_enterprises_for(user_cbe_numbers, @target_date)
      if matching_publications.empty?
        return EnterpriseResults.new(match: false, matching: nil)
      else
        matching_enterprises = matching_publications.map(&:enterprise).compact # Not likely to occur, but Publication#enterprise may return nil with new entity
        matching = matching_enterprises.map { EnterpriseResult.new(cbe_number: _1.id, denomination: _1.denominations.first.description) }
        return EnterpriseResults.new(match: true, matching: matching)
      end
    end
  end
end
