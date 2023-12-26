module Yocm
  class App
    hash_branch("enterprises") do |r|
      r.is String do |cbe_number|
        enterprise = Enterprise[cbe_number]

        unless enterprise
          response.status = 404
          r.halt
        end

        @publications = enterprise.publications

        view "enterprise", locals: {enterprise: enterprise}
      end
    end
  end
end
