;;; export
;;(require 'org-publish)
(setq org-publish-project-alist
      '(
	;; thes are the main web files
	("org-notes"
	 :base-directory "~/Documents/github/dany1.github.io/blog"
	 :base-extension "org"
	 :publishing-directory "~/Documents/github/dany1.github.io/publish_html/"
	 :recursive t
	 :publishing-function org-html-publish-to-html
	 :headline-levels 4
	 :auto-preamble nil
	 :auto-sitemap t
	 :sitemap-filename "sitemap.org"
	 :sitemap-title "sitemap"
	 :sitemap-file-entry-format "%d %t"
	 :section-numbers nil
	 :table-of-contents t
	 :html-head "<link rel='stylesheet' type='text/css' href='css/org-manual.css'/>"
	 :style-include-default nil
	 )

	;;these are static files
	("org-static"
	 :base-directory "~/Documents/github/dany1.github.io/blog"
	 :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pef\\|mp3\\|ogg\\|swf\\|txt"
	 :publishing-directory "~/Documents/github/dany1.github.io/publish_html"
	 :recursive t
	 :publishing-function org-publish-attachment
	 )
	("org"
	 :components("org-notes" "org-static"))
	)
      )
(defun blog-publish nil
  "publish blog."
  (interactive)
  (org-publish-all))

(blog-publish)
