describe 'faceting' do
  describe 'on fields' do
    it 'does not turn faceting on if no facet requested' do
      session.search(Post)
      connection.should_not have_last_search_with('facet')
    end

    it 'turns faceting on if facet is requested' do
      session.search Post do
        facet :category_ids
      end
      connection.should have_last_search_with(:facet => 'true')
    end

    it 'requests single field facet' do
      session.search Post do
        facet :category_ids
      end
      connection.should have_last_search_with(:"facet.field" => %w(category_ids_im))
    end

    it 'requests multiple field facets' do
      session.search Post do
        facet :category_ids, :blog_id
      end
      connection.should have_last_search_with(:"facet.field" => %w(category_ids_im blog_id_i))
    end

    it 'sets facet sort by count' do
      session.search Post do
        facet :category_ids, :sort => :count
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.sort" => 'true')
    end

    it 'sets facet sort by index' do
      session.search Post do
        facet :category_ids, :sort => :index
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.sort" => 'false')
    end

    it 'raises ArgumentError if bogus facet sort provided' do
      lambda do
        session.search Post do
          facet :category_ids, :sort => :sideways
        end
      end.should raise_error(ArgumentError)
    end

    it 'sets the facet limit' do
      session.search Post do
        facet :category_ids, :limit => 10
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.limit" => 10)
    end

    it 'sets the facet minimum count' do
      session.search Post do
        facet :category_ids, :minimum_count => 5
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 5)
    end

    it 'sets the facet minimum count to zero if zeros are allowed' do
      session.search Post do
        facet :category_ids, :zeros => true
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 0)
    end

    it 'sets the facet minimum count to one by default' do
      session.search Post do
        facet :category_ids
      end
      connection.should have_last_search_with(:"f.category_ids_im.facet.mincount" => 1)
    end
  end

  describe 'on time ranges' do
    before :each do
      @time_range = (Time.parse('2009-06-01 00:00:00 -0400')..
                     Time.parse('2009-07-01 00:00:00 -0400'))
    end

    it 'does not send date facet parameters if time range is not specified' do
      session.search Post do |query|
        query.facet :published_at
      end
      connection.should_not have_last_search_with(:"facet.date")
    end

    it 'sets the facet to a date facet if time range is specified' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(:"facet.date" => ['published_at_d'])
    end

    it 'sets the facet start and end' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(
        :"f.published_at_d.facet.date.start" => '2009-06-01T04:00:00Z',
        :"f.published_at_d.facet.date.end" => '2009-07-01T04:00:00Z'
      )
    end

    it 'defaults the time interval to 1 day' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range
      end
      connection.should have_last_search_with(:"f.published_at_d.facet.date.gap" => "+86400SECONDS")
    end

    it 'uses custom time interval' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range, :time_interval => 3600
      end
      connection.should have_last_search_with(:"f.published_at_d.facet.date.gap" => "+3600SECONDS")
    end

    it 'allows computation of one other time' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range, :time_other => :before
      end
      connection.should have_last_search_with(:"f.published_at_d.facet.date.other" => %w(before))
    end

    it 'allows computation of two other times' do
      session.search Post do |query|
        query.facet :published_at, :time_range => @time_range, :time_other => [:before, :after]
      end
      connection.should have_last_search_with(:"f.published_at_d.facet.date.other" => %w(before after))
    end

    it 'does not allow computation of bogus other time' do
      lambda do
        session.search Post do |query|
          query.facet :published_at, :time_range => @time_range, :time_other => :bogus
        end
      end.should raise_error(ArgumentError)
    end

    it 'does not allow date faceting on a non-date field' do
      lambda do
        session.search Post do |query|
          query.facet :blog_id, :time_range => @time_range
        end
      end.should raise_error(ArgumentError)
    end
  end

  describe 'using queries' do
    it 'turns faceting on' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(:facet => 'true')
    end

    it 'facets by query' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(:"facet.query" => 'average_rating_f:[4\.0 TO 5\.0]')
    end

    it 'requests multiple query facets' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:average_rating).between(3.0..4.0)
          end
          row :baz do
            with(:average_rating).between(4.0..5.0)
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => [
          'average_rating_f:[3\.0 TO 4\.0]',
          'average_rating_f:[4\.0 TO 5\.0]'
        ]
      )
    end

    it 'requests query facet with multiple conditions' do
      session.search Post do
        facet :foo do
          row :bar do
            with(:category_ids, 1)
            with(:blog_id, 2)
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => '(category_ids_im:1 AND blog_id_i:2)'
      )
    end

    it 'requests query facet with disjunction' do
      session.search Post do
        facet :foo do
          row :bar do
            any_of do
              with(:category_ids, 1)
              with(:blog_id, 2)
            end
          end
        end
      end
      connection.should have_last_search_with(
        :"facet.query" => '(category_ids_im:1 OR blog_id_i:2)'
      )
    end

    it 'does not allow 0 arguments to facet method with block' do
      lambda do
        session.search Post do
          facet do
          end
        end
      end.should raise_error(ArgumentError)
    end

    it 'does not allow more than 1 argument to facet method with block' do
      lambda do
        session.search Post do
          facet :foo, :bar do
          end
        end
      end.should raise_error(ArgumentError)
    end
  end
end
