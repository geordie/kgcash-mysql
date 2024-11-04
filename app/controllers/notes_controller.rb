class NotesController < ApplicationController
  before_action :set_note, only: [:show, :edit, :update, :destroy]

  def index
    @notes = current_user.notes
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notes }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @note }
    end
  end

  def create
    @note = current_user.notes.build(note_params)
    if @note.save
      respond_to do |format|
        format.html { redirect_to @note, notice: 'Note was successfully created.' }
        format.json { render json: @note, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def new
    @note = Note.new

    respond_to do |format|
      format.html # new.html.erb
      format.json {render json: @note}
    end
  end

  def update
    if @note.update(note_params)
      respond_to do |format|
        format.html { redirect_to @note, notice: 'Note was successfully updated.' }
        format.json { render json: @note }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @note.destroy
    respond_to do |format|
      format.html { redirect_to notes_url, notice: 'Note was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_note
    @user = current_user
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:note_text, :amount, :transaction_id)
  end
end
