import { useState } from 'react';
import { Box, Button, Section, Stack, Tabs } from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import { capitalizeAll } from 'tgui-core/string';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { InfoSection } from './RapidConstructionDevice';

type Data = {
  selected_icon: string;
  tile_dirs: string[];
  selected_direction: string;
  selected_category: string;
  selected_recipe: string;
  categories: Category[];
};

type Category = {
  category_name: string;
  recipes: Design[];
};

type Design = {
  name: string;
  icon: string;
};

const TilePreview = (props) => {
  const { data } = useBackend<Data>();
  const { selected_icon, selected_direction } = data;

  return (
    <Section
      backgroundColor="green"
      style={{
        width: '50px',
        height: '50px',
      }}
    >
      <Box
        className={classes([
          'rtd32x32',
          `${selected_icon}${selected_direction ? `${selected_direction}` : 'south'}`,
        ])}
      />
    </Section>
  );
};

const DirectionSelect = (props) => {
  const { act, data } = useBackend<Data>();
  const { tile_dirs = [], selected_direction } = data;
  return (
    <Section fill>
      <Stack vertical>
        {tile_dirs.map((dir) => (
          <Stack.Item key={dir}>
            <Button.Checkbox
              content={dir}
              color="transparent"
              checked={dir === selected_direction}
              onClick={() =>
                act('set_dir', {
                  dir: dir,
                })
              }
            />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const TileRotateSection = (props) => {
  const { data } = useBackend<Data>();
  const { selected_direction } = data;
  return (
    <Stack fill vertical>
      <Stack.Item>
        <TilePreview />
      </Stack.Item>
      <Stack.Item grow>
        {selected_direction !== null ? <DirectionSelect /> : ''}
      </Stack.Item>
    </Stack>
  );
};

const TileDesignSection = (props) => {
  const { act, data } = useBackend<Data>();
  const { categories = [], selected_category, selected_recipe } = data;
  const [categoryName, setCategoryName] = useState(selected_category);
  const shownCategory =
    categories.find((category) => category.category_name === categoryName) ||
    categories[0];

  return (
    <Section fill scrollable>
      <Tabs>
        {categories.map((category) => (
          <Tabs.Tab
            key={category.category_name}
            selected={category.category_name === categoryName}
            onClick={() => setCategoryName(category.category_name)}
          >
            {category.category_name}
          </Tabs.Tab>
        ))}
      </Tabs>
      {shownCategory?.recipes.map((recipe, i) => (
        <Button
          key={i + 1}
          fluid
          color="transparent"
          selected={
            recipe.name === selected_recipe &&
            shownCategory.category_name === selected_category
          }
          style={{
            height: '35px',
          }}
          onClick={() =>
            act('recipe', {
              category_name: shownCategory.category_name,
              id: i + 1,
            })
          }
        >
          <Box
            inline
            verticalAlign="middle"
            mr="20px"
            className={classes(['rtd32x32', `${recipe.icon}south`])}
          />
          <span>{capitalizeAll(recipe.name)}</span>
        </Button>
      ))}
    </Section>
  );
};

export const RapidTilingDevice = (props) => {
  return (
    <Window width={500} height={540}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <InfoSection />
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item>
                <TileRotateSection />
              </Stack.Item>
              <Stack.Item grow>
                <TileDesignSection />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
