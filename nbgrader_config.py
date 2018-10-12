c = get_config()

# paths
c.CourseDirectory.root = "/home/lukes/pyling"
c.Exchange.course_id = "pyling"
c.Exchange.root =  "/cnk/work/edu/exchange"
c.Exchange.timezone = "Europe/Prague"

# translations
c.ClearSolutions.code_stub = {
    "python": "# NÁSLEDUJÍCÍ ŘÁDEK SMAŽTE A DOPLŇTE MÍSTO NĚJ ŘEŠENÍ\nraise NotImplementedError",
}
c.ClearSolutions.text_stub = "**DVOJKLIKNĚTE NA TUTO BUŇKU A SVOU ODPOVĚĎ VPIŠTE MÍSTO TOHOTO TEXTU**"

# timeout
c.ExecutePreprocessor.timeout = 120
