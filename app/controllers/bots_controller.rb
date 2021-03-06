# frozen_string_literal: true

class BotsController < ApplicationController
  before_action :set_bot, only: [:show, :edit, :update, :destroy]
  before_action :set_game

  # GET /bots or /bots.json
  def index
    @bots = Bot.all
  end

  # GET /bots/1 or /bots/1.json
  def show
  end

  # GET /bots/new
  def new
    @bot = Bot.new
  end

  # GET /bots/1/edit
  def edit
    @layers = @bot.transfer_layers
  end

  # POST /bots or /bots.json
  def create
    @bot = Bot.new(bot_params)
    @bot.game_id = params[:game_id]

    if @bot.save
      StandardBuilder.new(@bot).call
      redirect_to game_path(@game), notice: "Bot was successfully created."
    else
      flash[:error] = @bot.errors.map(&:full_message).join("\n")
      render :new
    end
  end

  # PATCH/PUT /bots/1 or /bots/1.json
  def update
    respond_to do |format|
      if @bot.update(bot_params)
        format.html { redirect_to @bot, notice: "Bot was successfully updated." }
        format.json { render :show, status: :ok, location: @bot }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @bot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bots/1 or /bots/1.json
  def destroy
    @bot.destroy
    respond_to do |format|
      format.html { redirect_to bots_url, notice: "Bot was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bot
    @bot = Bot.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def bot_params
    params.require(:bot).permit(:name, :static)
  end

  def set_game
    @game = Game.find(params[:game_id])
  end
end
