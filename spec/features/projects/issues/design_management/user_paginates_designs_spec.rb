# frozen_string_literal: true

require 'spec_helper'

describe 'User paginates issue designs', :js do
  include DesignManagementTestHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    enable_design_management

    create_list(:design, 2, :with_file, issue: issue)

    visit project_issue_path(project, issue)

    click_link 'Designs'

    wait_for_requests

    find('.js-design-list-item', match: :first).click
  end

  it 'paginates to next design' do
    expect(find('.js-previous-design')[:disabled]).to eq('true')

    page.within(find('.js-design-header')) do
      expect(page).to have_content('1 of 2')
    end

    find('.js-next-design').click

    expect(find('.js-previous-design')[:disabled]).not_to eq('true')

    page.within(find('.js-design-header')) do
      expect(page).to have_content('2 of 2')
    end
  end
end
