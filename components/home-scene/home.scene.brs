function showScreen(screen)
  m.top.focusedChild.visible = false
  screenToShow = m.top.findNode(screen.screenId)
  screenToShow.visible = true
  if screen.content <> invalid then screenToShow.content = screen.content
  screenToShow.setFocus(true)

  return true
end function

sub showNewScreenWithSavingCurrent(screenToShowId)
  currentScreen = m.top.findNode(m.top.focusedChild.id)
  historyItem = { screenId: m.top.focusedChild.id, content: currentScreen.content }
  m.screensHistory.push(historyItem)
  showScreen({ screenId: screenToShowId })
end sub

function handleReceivedMovies(movies)
  showNewScreenWithSavingCurrent(m.movieListScreen.id)
  m.movieListScreen.content = movies
end function

function handleReceivedConfig(config)
  m.APIKey = config.APIKey
  m.baseUrl = config.baseUrl
  params = { config: config }
  m.headerScreen.callFunc("setHeaderListContent", params)
  m.detailsScreen.callFunc("setDetailsContent", params)
  m.movieListScreen.callFunc("updateDummyVideos", params)
end function

function handleMovieGenres(genres)
  content = m.detailsScreen.content
  content.genres = genres
  m.detailsScreen.content = content
end function

function handleCast(cast)
  showNewScreenWithSavingCurrent(m.peopleScreen.id)
  castContent = { title: "Cast of " + m.movieTitle, peopleList: cast }
  m.peopleScreen.content = castContent
end function

function handleReviews(reviews)
  showNewScreenWithSavingCurrent(m.reviewsScreen.id)
  reviewsContent = { title: "Reviews of " + m.movieTitle, reviews: reviews }
  m.reviewsScreen.content = reviewsContent
end function

sub handleKnownForMovies(movies)
  m.personScreen.knownForMovies = movies
end sub

sub handleMovies(movies)
  if m.personScreen.visible = true then handleKnownForMovies(movies) else handleReceivedMovies(movies)
end sub

sub handlePopularActors(popularActorsList)
  showNewScreenWithSavingCurrent(m.peopleScreen.id)
  popularActorsListContent = { title: "Popular Actors", peopleList: popularActorsList }
  m.peopleScreen.content = popularActorsListContent
end sub

function handleResults(results)
  if results[0].title <> invalid
    handleMovies(results)
  else if results[0].author <> invalid
    handleReviews(results)
  else if results[0].name <> invalid
    handlePopularActors(results)
  end if
end function

sub handlePersonDetails(personDetails)
  m.personScreen.personDetails = personDetails
end sub

sub handleData(data)
  results = data.results
  categories = data.categories
  genres = data.genres
  cast = data.cast
  name = data.name

  if results <> invalid and results.count() > 0
    handleResults(results)
  else if categories <> invalid and categories.count() > 0
    handleReceivedConfig(data)
  else if genres <> invalid and genres.count() > 0
    handleMovieGenres(genres)
  else if cast <> invalid and cast.count() > 0
    handleCast(data.cast)
  else if name <> invalid
    handlePersonDetails(data)
  else
    showErrorDialog("No data found.")
  end if
end sub

sub fetch(url)
  m.asyncTask = createObject("roSGNode", "LoadAsyncTask")
  m.asyncTask.observeField("error", "fetchErrorHandler")
  m.asyncTask.observeField("response", "fetchResponseHandler")
  m.asyncTask.url = url
  m.asyncTask.control = "RUN"
end sub

sub showTrendingThisWeek(urlToMakeQuery)
  m.movieListScreen.title = "Trending This Week"
  fetch(urlToMakeQuery)
end sub

sub showPopularActorsList(urlToMakeQuery)
  fetch(urlToMakeQuery)
end sub

function getContentForMovieDetailsScreen(movieContentNode)
  content = {
    title: movieContentNode.SHORTDESCRIPTIONLINE1,
    description: movieContentNode.SHORTDESCRIPTIONLINE2,
    id: movieContentNode.id
  }

  HDGRIDPOSTERURL = movieContentNode.HDGRIDPOSTERURL
  HDPOSTERURL = movieContentNode.HDPOSTERURL

  if HDGRIDPOSTERURL <> invalid and HDGRIDPOSTERURL <> ""
    content.posterUrl = HDGRIDPOSTERURL
  else if HDPOSTERURL <> invalid and HDPOSTERURL <> ""
    content.posterUrl = HDPOSTERURL
  end if

  return content
end function

sub stopVideo()
  m.videoPlayer.control = "stop"
end sub

sub initializeVideoPlayer()
  m.videoPlayer.EnableCookies()
  m.videoPlayer.setCertificatesFile("common:/certs/ca-bundle.crt")
  m.videoPlayer.InitClientCertificates()
  m.videoPlayer.notificationInterval = 10
  m.videoPlayer.observeFieldScoped("position", "playerPositionChangeHandler")
  m.videoPlayer.observeFieldScoped("state", "playerStateChangeHandler")
end sub

sub showErrorDialog(message)
  m.errorDialog.title = "ERROR"
  m.errorDialog.message = message
  m.errorDialog.visible = true
  m.top.dialog = m.errorDialog
end sub

sub setMovieTitle(obj)
  m.movieTitle = obj.getData()
end sub

sub fetchKnownFor(obj)
  personId = obj.getData()
  knownForUrl = m.baseUrl + "/discover/movie" + m.APIKey + "&language=en-US&sort_by=popularity.desc&include_adult=false&page=1&with_cast=" + personId.toStr()
  fetch(knownForUrl)
end sub

sub fetchPersonDetails(obj)
  personId = obj.getData()
  personUrl = m.baseUrl + "/person/" + personId.toStr() + m.APIKey + "&language=en-US"
  fetch(personUrl)
end sub

sub fetchMovieGenres(obj)
  m.movieId = obj.getData()
  genresUrl = m.baseUrl + "/movie/" + m.movieId.toStr() + m.APIKey + "&language=en-US"
  fetch(genresUrl)
end sub

function init()
  ? "[home_scene] init"
  m.headerScreen = m.top.findNode("headerScreen")
  m.movieListScreen = m.top.findNode("movieListScreen")
  m.searchForMoviesScreen = m.top.findNode("searchForMoviesScreen")
  m.detailsScreen = m.top.findNode("detailsScreen")
  m.peopleScreen = m.top.findNode("peopleScreen")
  m.reviewsScreen = m.top.findNode("reviewsScreen")
  m.personScreen = m.top.findNode("personScreen")
  m.errorDialog = m.top.findNode("errorDialog")
  m.videoPlayer = m.top.findNode("videoPlayer")

  m.headerScreen.observeField("pageSelected", "categoryClickHandler")
  m.searchForMoviesScreen.observeField("searchButtonClicked", "searchButtonClickHandler")
  m.movieListScreen.observeField("movieSelected", "movieClickHandler")
  m.personScreen.observeField("knownForMovieSelected", "knownForMovieClickHandler")
  m.detailsScreen.observeField("playButtonPressed", "playButtonClickHandler")
  m.detailsScreen.observeField("fetchMovieGenres", "fetchMovieGenres")
  m.detailsScreen.observeField("additionalInformationSelected", "additionalInformationClickHandler")
  m.detailsScreen.observeField("setMovieTitle", "setMovieTitle")
  m.peopleScreen.observeField("personSelected", "personCLickHandler")
  m.personScreen.observeField("fetchPersonDetails", "fetchPersonDetails")
  m.personScreen.observeField("fetchKnownFor", "fetchKnownFor")

  initializeVideoPlayer()
  m.screensHistory = []
  m.headerScreen.setFocus(true)
  configUrl = "https://run.mocky.io/v3/9e42e605-84b7-4215-b1f5-fccae38df7a4"
  fetch(configUrl)
end function

function onKeyEvent(key, press) as boolean
  ? "[home_scene] onKeyEvent", key, press
  if key = "back" and press then return handleBackButtonClick()

  return false
end function