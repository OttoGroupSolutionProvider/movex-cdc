import { shallowMount } from '@vue/test-utils';
import App from '@/App.vue';

describe('App.vue', () => {
  it('renders login modal if no user is logged in', () => {
    const wrapper = shallowMount(App, {});
    expect(wrapper.find('b-modal-stub').exists()).toBeTruthy();
  });

  it('renders application if user is logged in', () => {
    const wrapper = shallowMount(App, {
      data() {
        return {
          loggedIn: true,
        };
      },
    });
    expect(wrapper.find('router-view-stub').exists()).toBeTruthy();
  });
});
