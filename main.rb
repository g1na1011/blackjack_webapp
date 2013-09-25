require "rubygems"
require "sinatra"
require "pry"

set :sessions, true

BLACKJACK_AMT = 21
DEALER_HIT_MIN = 17
INITIAL_POT_AMT = 500

helpers do
  def total_hand(cards)
    values = cards.map { |card| card[1] }

    total = 0
    values.each do |value|
      if value == "A"
        total += 11
      else  
        total += (value.to_i == 0 ? 10 : value.to_i) # This is for J, Q, K.
      end     
    end

    # Corrects the Ace if total is > BLACKJACK_AMT.
    values.select { |value| value == "A" }.count.times do
      break if total <= BLACKJACK_AMT
      total -= 10
    end

    total
  end

  def card_image(card) # input ["H", "5"]
    suit = case card[0]
      when "S" then "spades"
      when "H" then "hearts"
      when "C" then "clubs"
      when "D" then "diamonds"
    end

    value = card[1]
    if ["J", "Q", "K", "A"].include?(value)
      value = case card[1]
        when "J" then "jack"
        when "Q" then "queen"
        when "K" then "king"
        when "A" then "ace"
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'/>"
  end

  def instant_bj!(msg)
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    @show_hit_stand_btn = false
    @play_again_btn = true
    session[:player_pot] = session[:player_pot] + (session[:bet_amount] * 1.5).to_i
  end

  def winner!(msg)
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    @show_hit_stand_btn = false
    @play_again_btn = true
    session[:player_pot] = session[:player_pot] + session[:bet_amount].to_i
  end

  def loser!(msg)
    @loser = "<strong>Sorry, #{session[:player_name]} loses.</strong> #{msg}"
    @show_hit_stand_btn = false
    @play_again_btn = true
    session[:player_pot] = session[:player_pot] - session[:bet_amount].to_i
  end

  def tie!(msg)
    @winner = "<strong>It's a tie!</strong> #{msg}"
    @show_hit_stand_btn = false
    @play_again_btn = true
  end
   

end

before do
  @show_hit_stand_btn = true  
  @show_dealer_hit_btn = false
end

get "/" do
  session[:player_pot] = INITIAL_POT_AMT
  erb :home
end

post "/new_player" do
  session[:player_name] = params[:player_name]

  if session[:player_name].empty?
    @error = "Please submit your name."
    halt erb :home
  end

  redirect "/bet"
end

get "/bet" do
  session[:bet_amount] = nil
  erb :bet
end

post "/bet" do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb :bet
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})."
    halt erb :bet
  else
    session[:bet_amount] = params[:bet_amount].to_i
    redirect "/game"
  end
end

get "/game" do
  session[:turn] = session[:player_name]

  # Create a deck and put it in a session.
  suits = ["S", "H", "C", "D"]
  values = ["2", "3", "4", "5", "6", "7", "8", "9","10", "J", "Q", "K", "A"]
  session[:deck] = suits.product(values).shuffle! # [["H", "8"], ["S", "3"]...]
  
  # Deal initial two cards for dealer/player.
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  player_total = total_hand(session[:player_cards])
  dealer_total = total_hand(session[:dealer_cards])

  if player_total == BLACKJACK_AMT
    instant_bj!("#{session[:player_name]} hits blackjack while dealer has #{dealer_total}.")
    session[:turn] = "dealer"
  elsif dealer_total == BLACKJACK_AMT
    loser!("Dealer hits blackjack while #{session[:player_name]} has #{player_total}.")
    session[:turn] = "dealer"
  end

  erb :game
end

post "/game/player/hit" do 
  session[:player_cards] << session[:deck].pop

  player_total = total_hand(session[:player_cards])
  dealer_total = total_hand(session[:dealer_cards])

  if total_hand(session[:player_cards]) > BLACKJACK_AMT
    loser!("#{session[:player_name]} busted at #{player_total} while dealer has #{dealer_total}.")
    session[:turn] = "dealer"
  end

  erb :game, layout: false
end

post "/game/player/stand" do
  redirect "/game/dealer/hit"
end

get "/game/dealer/hit" do
  player_total = total_hand(session[:player_cards])
  dealer_total = total_hand(session[:dealer_cards])

  session[:turn] = "dealer"
  @winner = "#{session[:player_name]} chose to stand at #{player_total}."
  @show_hit_stand_btn = false

  if dealer_total < DEALER_HIT_MIN
    @show_dealer_hit_btn = true
  else 
    redirect "/game/compare"
  end

  erb :game, layout: false
end

post "/game/dealer/hit" do
  session[:dealer_cards] << session[:deck].pop

  @show_hit_stand_btn = false
  dealer_total = total_hand(session[:dealer_cards])

  if dealer_total >= DEALER_HIT_MIN
    redirect "/game/compare"
  else
    redirect "/game/dealer/hit"
  end

  erb :game, layout: false
end

get "/game/compare" do
  player_total = total_hand(session[:player_cards])
  dealer_total = total_hand(session[:dealer_cards])

  if dealer_total > BLACKJACK_AMT
    winner!("Dealer busted at #{dealer_total} while #{session[:player_name]} has #{player_total}.")
  elsif player_total > dealer_total
    winner!("Dealer has #{dealer_total} while #{session[:player_name]} has #{player_total}.")
  elsif dealer_total > player_total
    loser!("Dealer has #{dealer_total} while #{session[:player_name]} has #{player_total}.")
  else
    tie!("Both the dealer and #{session[:player_name]} have #{player_total}.")    
  end

  erb :game, layout: false
end

get "/game_over" do
  erb :game_over
end




